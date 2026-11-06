import Foundation
import XCTest

/// A deliberately long-lived, opt-in test session serving the Mac MCP relay.
@MainActor
final class DeviceAutomationTests: XCTestCase {
    private struct Command: Decodable {
        let id: String
        let operation: String
        let identifier: String
        let text: String
    }

    private struct Envelope: Decodable {
        let command: Command?
    }

    func testServeCommands() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let endpoint = environment["STICK_MCP_BRIDGE_URL"],
              let url = URL(string: endpoint),
              let token = environment["STICK_MCP_TOKEN"], !token.isEmpty else {
            throw XCTSkip("Set STICK_MCP_BRIDGE_URL and STICK_MCP_TOKEN in the runner scheme's Test environment.")
        }
        executionTimeAllowance = 3_600
        let app = XCUIApplication(bundleIdentifier: "com.parbo.cheatah")
        let deadline = Date().addingTimeInterval(3_600)
        while Date() < deadline, !Task.isCancelled {
            var poll = URLRequest(url: url.appendingPathComponent("next"))
            poll.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            poll.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: poll)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                XCTFail("MCP relay rejected the connection; check its token and endpoint.")
                return
            }
            if let command = try JSONDecoder().decode(Envelope.self, from: data).command {
                let result = execute(command, in: app)
                var request = URLRequest(url: url.appendingPathComponent("result"))
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: result)
                request.timeoutInterval = 5
                let (_, reply) = try await URLSession.shared.data(for: request)
                guard (reply as? HTTPURLResponse)?.statusCode == 200 else {
                    XCTFail("MCP relay could not accept the command result.")
                    return
                }
            } else {
                try await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private func execute(_ command: Command, in app: XCUIApplication) -> [String: String] {
        var result = ["id": command.id]
        if command.operation == "activate" {
            app.activate()
            result["text"] = "Stick activated."
            return result
        }
        guard app.state == .runningForeground else {
            result["error"] = "Stick is not foreground. Call activate first."
            return result
        }
        switch command.operation {
        case "inspect":
            let elements = app.descendants(matching: .any).allElementsBoundByIndex
                .filter { $0.exists && !$0.frame.isEmpty && ($0.isHittable || !$0.identifier.isEmpty) }
                .prefix(300)
            result["text"] = elements.map {
                "type=\($0.elementType.rawValue) id=\($0.identifier.debugDescription) label=\($0.label.debugDescription) enabled=\($0.isEnabled) hittable=\($0.isHittable)"
            }.joined(separator: "\n")
        case "screenshot":
            result["png"] = app.screenshot().pngRepresentation.base64EncodedString()
        case "tap", "type_text":
            guard !command.identifier.isEmpty else {
                result["error"] = "An accessibility identifier is required."
                return result
            }
            let matches = app.descendants(matching: .any).matching(identifier: command.identifier)
            guard matches.firstMatch.waitForExistence(timeout: 5), matches.count == 1 else {
                result["error"] = "Expected one element for \(command.identifier); found \(matches.count)."
                return result
            }
            let element = matches.element(boundBy: 0)
            guard element.isEnabled, element.isHittable else {
                result["error"] = "Element is disabled or not hittable."
                return result
            }
            if command.operation == "type_text" {
                guard element.elementType == .textField || element.elementType == .secureTextField
                    || element.elementType == .textView else {
                    result["error"] = "Target is not a text input."
                    return result
                }
                element.tap()
                element.typeText(command.text)
            } else {
                element.tap()
            }
            result["text"] = "Completed \(command.operation) on \(command.identifier)."
        default:
            result["error"] = "Unknown operation."
        }
        return result
    }
}
