# Stick device MCP prototype

The MCP server runs on the Mac over stdio. A dedicated XCTest session on the
iPhone polls its HTTP relay, performs one XCUIAutomation command at a time,
and returns the result. Stick's app process contains no automation server.

Requires Python 3.10+, Xcode, and a signed UI-test runner for a physical device.
This prototype pins the MCP SDK to its 1.x API (`FastMCP`).

```sh
python3.13 -m venv /tmp/stick-device-mcp-venv
/tmp/stick-device-mcp-venv/bin/pip install -r tools/device-mcp/requirements.txt
tuist generate --no-open
```

Add this server to your MCP client's configuration, substituting absolute
paths and a freshly generated secret (`openssl rand -hex 32`):

```json
{
  "mcpServers": {
    "stick-device": {
      "command": "/tmp/stick-device-mcp-venv/bin/python",
      "args": ["/absolute/path/to/stick-app/tools/device-mcp/server.py"],
      "env": {
        "STICK_MCP_BIND": "0.0.0.0",
        "STICK_MCP_PORT": "8765",
        "STICK_MCP_TOKEN": "replace-with-your-random-secret"
      }
    }
  }
}
```

Start the server through your MCP client. Keep the Mac and iPhone on a trusted
local network. The relay is plain HTTP with a shared bearer token; use it only
on that trusted network. The default bind address is loopback, suitable for
Simulator; physical devices require the explicit network binding above.

In Xcode, select the **StickAutomation** scheme and your iPhone. Set signing
for Stick and StickAutomationRunner. In Edit Scheme → Test → Arguments,
configure these environment variables for the test process:

| Variable | Value |
| --- | --- |
| `STICK_MCP_BRIDGE_URL` | `http://your-mac-hostname.local:8765` |
| `STICK_MCP_TOKEN` | The same random secret as the MCP server |

Use `http://127.0.0.1:8765` for Simulator. Keep secrets in local scheme settings,
outside version control. Regenerating the workspace may replace scheme settings.
Allow local network access if prompted, then run
`DeviceAutomationTests.testServeCommands`. It remains active for up to one hour;
Xcode's test timeout settings may impose a shorter limit. Stop it in Xcode when
finished. Missing configuration skips the test. The regular Stick scheme excludes
this long-lived session.

Call MCP tools in this order for the original example:

```text
activate()
inspect()
tap(identifier="open-settings")
screenshot()
```

Tools: `activate`, `inspect`, `tap`, `type_text`, and `screenshot`. Actions are
restricted to Stick's current bundle ID, `com.parbo.cheatah`. Tap and text input
require a unique accessibility identifier. `type_text` inserts at the current
cursor; it does not clear existing content. Inspection returns up to 300 elements;
it is a flat observation, not a stable full accessibility-tree schema.

Run relay tests with:

```sh
cd tools/device-mcp
/tmp/stick-device-mcp-venv/bin/python -m unittest -v
```

Only one runner and one MCP server are supported. Restart the runner after a
connection failure. A timed-out action may already have executed: inspect before
retrying; the relay never automatically retries a dispatched action. Cancelling
an MCP call cannot undo a tap. XCTest may record an automation failure as a test
failure. The runner must remain in an active test session; launching its icon
alone does not start the command loop.

Sources: [Apple XCUIAutomation](https://developer.apple.com/documentation/XCUIAutomation),
[async XCTest](https://developer.apple.com/documentation/xctest/asynchronous-tests-and-expectations),
[execution allowance](https://developer.apple.com/documentation/xctest/xctestcase/executiontimeallowance),
[MCP SDK 1.x](https://github.com/modelcontextprotocol/python-sdk/tree/v1.x).
