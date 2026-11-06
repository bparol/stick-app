import queue
import threading
import time
import unittest

from server import Relay


class RelayTests(unittest.TestCase):
    def test_disconnected_runner_fails_without_queuing_actions(self):
        relay = Relay()
        with self.assertRaisesRegex(RuntimeError, "disconnected"):
            relay.execute("tap", "open-settings")
        self.assertTrue(relay.commands.empty())

    def test_commands_are_serial_and_results_are_correlated(self):
        relay = Relay()
        relay.last_seen = time.monotonic()
        outcomes = []
        first = threading.Thread(target=lambda: outcomes.append(relay.execute("activate")))
        second = threading.Thread(target=lambda: outcomes.append(relay.execute("tap", "open-settings")))
        first.start()
        command = relay.commands.get(timeout=1)
        second.start()
        self.assertEqual(command["operation"], "activate")
        with self.assertRaises(queue.Empty):
            relay.commands.get(timeout=0.05)
        relay.results[command["id"]].put({"text": "activated"})
        first.join(timeout=1)
        command = relay.commands.get(timeout=1)
        self.assertEqual(command["identifier"], "open-settings")
        relay.results[command["id"]].put({"text": "tapped"})
        second.join(timeout=1)
        self.assertEqual(outcomes, [{"text": "activated"}, {"text": "tapped"}])
        self.assertFalse(relay.results)

    def test_expired_queued_command_is_never_dispatched(self):
        relay = Relay()
        relay.commands.put({"id": "expired", "operation": "tap"})
        self.assertIsNone(relay.next_command())

    def test_action_errors_propagate(self):
        relay = Relay()
        relay.last_seen = time.monotonic()

        def respond():
            command = relay.commands.get(timeout=1)
            relay.results[command["id"]].put({"error": "Element is disabled"})

        runner = threading.Thread(target=respond)
        runner.start()
        with self.assertRaisesRegex(RuntimeError, "disabled"):
            relay.execute("tap", "save-domain")
        runner.join(timeout=1)


if __name__ == "__main__":
    unittest.main()
