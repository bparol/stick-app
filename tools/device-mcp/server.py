"""Local MCP server and HTTP command relay for Stick's XCTest runner."""
import asyncio
import base64
import hmac
import json
import os
import queue
import secrets
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from mcp.server.fastmcp import FastMCP, Image


class Relay:
    def __init__(self):
        self.commands = queue.Queue()
        self.results = {}
        self.lock = threading.Lock()
        self.serial = threading.Lock()
        self.last_seen = 0.0

    def execute(self, operation, identifier="", text=""):
        with self.serial:
            if time.monotonic() - self.last_seen > 5:
                raise RuntimeError("Runner is disconnected. Start testServeCommands in Xcode.")
            command_id = secrets.token_hex(16)
            response = queue.Queue(maxsize=1)
            with self.lock:
                self.results[command_id] = response
            self.commands.put(dict(id=command_id, operation=operation,
                                   identifier=identifier, text=text))
            try:
                result = response.get(timeout=25)
            except queue.Empty:
                raise RuntimeError("Runner timed out; action outcome is unknown. Inspect before retrying.") from None
            finally:
                with self.lock:
                    self.results.pop(command_id, None)
            if result.get("error"):
                raise RuntimeError(result["error"])
            return result

    def next_command(self):
        self.last_seen = time.monotonic()
        while True:
            try:
                command = self.commands.get_nowait()
            except queue.Empty:
                return None
            with self.lock:
                if command["id"] in self.results:
                    return command


def make_handler(relay, token):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # stdout belongs exclusively to MCP.

        def reply(self, status, payload):
            body = json.dumps(payload).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def authorized(self):
            return hmac.compare_digest(self.headers.get("Authorization", ""), "Bearer " + token)

        def do_GET(self):
            if not self.authorized():
                return self.reply(401, {"error": "Unauthorized"})
            if self.path != "/next":
                return self.reply(404, {})
            self.reply(200, {"command": relay.next_command()})

        def do_POST(self):
            if not self.authorized():
                return self.reply(401, {"error": "Unauthorized"})
            if self.path != "/result":
                return self.reply(404, {})
            try:
                size = int(self.headers.get("Content-Length", "0"))
                if not 0 < size <= 20_000_000:
                    return self.reply(413, {})
                result = json.loads(self.rfile.read(size))
                with relay.lock:
                    destination = relay.results.get(result["id"])
                    if destination is not None:
                        destination.put_nowait(result)
            except (ValueError, KeyError, TypeError, queue.Full):
                return self.reply(400, {})
            self.reply(200, {})
    return Handler


relay = Relay()
mcp = FastMCP("Stick Device")


@mcp.tool()
async def activate() -> str:
    """Launch Stick or bring its current UI to the foreground; preserves navigation and data."""
    return (await asyncio.to_thread(relay.execute, "activate"))["text"]


@mcp.tool()
async def inspect() -> str:
    """List visible accessibility elements and identifiers in Stick. Use before choosing a tap target."""
    return (await asyncio.to_thread(relay.execute, "inspect"))["text"]


@mcp.tool()
async def tap(identifier: str) -> str:
    """Tap one uniquely matching accessibility identifier in Stick, e.g. open-settings."""
    return (await asyncio.to_thread(relay.execute, "tap", identifier))["text"]


@mcp.tool()
async def type_text(identifier: str, text: str) -> str:
    """Focus a uniquely identified text field in Stick and insert text at its current cursor."""
    return (await asyncio.to_thread(relay.execute, "type_text", identifier, text))["text"]


@mcp.tool()
async def screenshot() -> Image:
    """Capture Stick's current UI as a PNG image."""
    result = await asyncio.to_thread(relay.execute, "screenshot")
    return Image(data=base64.b64decode(result["png"]), format="png")


def main():
    token = os.environ.get("STICK_MCP_TOKEN", "")
    if len(token) < 24:
        raise SystemExit("Set STICK_MCP_TOKEN to a random secret of at least 24 characters.")
    host = os.environ.get("STICK_MCP_BIND", "127.0.0.1")
    port = int(os.environ.get("STICK_MCP_PORT", "8765"))
    server = ThreadingHTTPServer((host, port), make_handler(relay, token))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"Stick runner relay listening on {host}:{port}", file=sys.stderr)
    try:
        mcp.run(transport="stdio")
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
