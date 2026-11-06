import XCTest
import CoreGraphics

@MainActor
final class NavigationTests: XCTestCase {
    func testFirstUseExamplesAdvanceAndCancellingDoesNotCreateADomain() {
        let app = launchFreshApp()
        XCTAssertTrue(app.staticTexts["What domain will you focus on today?"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["A little time counts."].exists)
        let example = app.descendants(matching: .any).matching(identifier: "domain-example").firstMatch
        XCTAssertTrue(example.exists)
        let initialExample = example.label
        keepScreenshot(of: app, name: "First-use card")
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialExample), object: example
        )
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 7), .completed)
        keepScreenshot(of: app, name: "Next example")

        app.buttons["add-first-domain"].tap()
        let field = app.textFields["domain-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["save-domain"].isEnabled)
        field.tap()
        field.typeText("  ")
        XCTAssertFalse(app.buttons["save-domain"].isEnabled)
        app.buttons["cancel-domain"].tap()
        XCTAssertTrue(app.buttons["add-first-domain"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["add-first-domain"].waitForExistence(timeout: 10))
    }

    func testFirstSavedDomainReplacesIntroductionAndSurvivesRelaunch() {
        let app = launchFreshApp()
        addFirstDomain(in: app, named: "Guitar")
        XCTAssertTrue(app.staticTexts["focus-card-prompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Guitar"].exists)
        XCTAssertFalse(app.staticTexts["A little time counts."].exists)
        XCTAssertFalse(app.buttons["add-first-domain"].exists)
        keepScreenshot(of: app, name: "Saved first domain")

        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Guitar"].exists)
        app.buttons["add-domain"].tap()
        enterDomainNameAndSave(in: app, named: "Reading")
        XCTAssertTrue(app.buttons["Guitar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Reading"].exists)
        keepScreenshot(of: app, name: "Saved domains in Settings")
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["session-toggle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Guitar"].exists)
        XCTAssertFalse(app.buttons["add-first-domain"].exists)
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Guitar"].exists)
        XCTAssertTrue(app.buttons["Reading"].exists)
    }

    func testSessionPauseResumeRelaunchAndStopToast() {
        let app = launchFreshApp()
        addFirstDomain(in: app, named: "Photography")
        let toggle = app.buttons["session-toggle"]
        let stop = app.buttons["session-stop"]
        XCTAssertEqual(toggle.label, "Start")
        XCTAssertFalse(stop.exists)
        assertStatus("waiting", for: "Photography", in: app)
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "started")
        XCTAssertTrue(toggle.label.hasPrefix("Pause ("))
        XCTAssertTrue(stop.exists)
        XCTAssertFalse(app.staticTexts["session-total-toast"].exists)
        keepScreenshot(of: app, name: "Running session")
        assertStatus("started", for: "Photography", in: app)
        app.terminate()
        app.launch()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, "started")
        toggle.tap()
        XCTAssertEqual(toggle.label, "Continue")
        XCTAssertTrue(stop.exists)
        XCTAssertFalse(app.staticTexts["session-total-toast"].exists)
        keepScreenshot(of: app, name: "Paused session")
        assertStatus("paused", for: "Photography", in: app)
        keepScreenshot(of: app, name: "Paused session after Settings")
        app.terminate()
        app.launch()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.label, "Continue")
        XCTAssertTrue(stop.exists)
        XCTAssertTrue(stop.isHittable)
        XCTAssertGreaterThan(stop.frame.minX, toggle.frame.maxX)
        XCTAssertLessThanOrEqual(stop.frame.maxX, app.frame.maxX)
        keepScreenshot(of: app, name: "Paused session after relaunch")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "started")
        toggle.tap()
        stop.tap() // Stopping directly from paused is supported.
        XCTAssertEqual(toggle.label, "Start")
        XCTAssertFalse(stop.exists)
        let toast = app.staticTexts["session-total-toast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 2))
        XCTAssertTrue(toast.label.contains("Photography"))
        XCTAssertTrue(toast.label.contains("total for"))
        keepScreenshot(of: app, name: "Stopped session total")
        XCTAssertTrue(toast.waitForNonExistence(timeout: 8))
        app.terminate()
        app.launch()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.label, "Start")
    }

    private func assertStatus(_ status: String, for name: String, in app: XCUIApplication) {
        app.buttons["open-settings"].tap()
        let row = app.buttons[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(row.value as? String, status)
        XCTAssertFalse(app.staticTexts["Today"].exists)
        XCTAssertFalse(app.switches["daily-rotation"].exists)
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
    }

    func testSettingsRoundTrip() {
        let app = launchFreshApp()

        XCTAssertTrue(app.staticTexts["What domain will you focus on today?"].waitForExistence(timeout: 10))
        assertHomeHeader(in: app)
        assertWorldRenders(in: app)
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Choose what you want to make time for."].exists)

        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["What domain will you focus on today?"].waitForExistence(timeout: 5))

        // A second visit catches stale paths or a broken native back binding.
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["What domain will you focus on today?"].waitForExistence(timeout: 5))
        assertHomeHeader(in: app)
        assertWorldRenders(in: app)
    }

    func testHeaderAtLargestAccessibilityTextSize() {
        let app = launchFreshApp(arguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])

        XCTAssertTrue(app.staticTexts["What domain will you focus on today?"].waitForExistence(timeout: 10))
        assertHomeHeader(in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEditingDuringSessionPreservesCursorAndDeletingCurrentAdvances() {
        let app = launchFreshApp()
        addFirstDomain(in: app, named: "Photography")
        app.buttons["session-toggle"].tap()
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.buttons["Photography"].waitForExistence(timeout: 5))
        app.buttons["Photography"].tap()
        let field = app.textFields["domain-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Photography".count))
        field.typeText("Camera")
        app.buttons["save-domain"].tap()
        XCTAssertTrue(app.buttons["Camera"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Camera"].value as? String, "started")
        app.buttons["add-domain"].tap()
        enterDomainNameAndSave(in: app, named: "Reading")
        let readingID = app.buttons["Reading"].identifier
        let cameraID = app.buttons["Camera"].identifier
        app.buttons["edit-domains"].tap()
        let reading = app.descendants(matching: .any).matching(identifier: readingID).firstMatch
        let camera = app.descendants(matching: .any).matching(identifier: cameraID).firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 5))
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: app.frame.maxX - 42, dy: reading.frame.midY)
        )
        let end = app.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: app.frame.maxX - 42, dy: camera.frame.midY - 8)
        )
        start.press(forDuration: 0.8, thenDragTo: end)
        app.buttons["edit-domains"].tap()
        XCTAssertLessThan(app.buttons["Reading"].frame.midY, app.buttons["Camera"].frame.midY)
        XCTAssertEqual(app.buttons["Camera"].value as? String, "started")
        keepScreenshot(of: app, name: "User order with active cursor")
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Camera"].exists)
        app.buttons["session-stop"].tap()
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")
        app.buttons["session-toggle"].tap()
        app.buttons["open-settings"].tap()
        app.buttons["Reading"].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["Camera"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Camera"].value as? String, "waiting")
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Camera"].exists)
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")
        app.buttons["open-settings"].tap()
        app.buttons["Camera"].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Choose what you want to make time for."].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["add-first-domain"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["add-first-domain"].waitForExistence(timeout: 10))
    }

    func testSessionHistoryNavigationDeletionAndUnfinishedResetSurviveRelaunch() {
        let app = launchFreshApp()
        app.buttons["open-settings"].tap()
        app.buttons["open-sessions"].tap()
        XCTAssertTrue(app.navigationBars["Sessions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No sessions yet"].exists)
        keepScreenshot(of: app, name: "Empty session history")
        app.navigationBars["Sessions"].buttons.element(boundBy: 0).tap()
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        addFirstDomain(in: app, named: "Photography")
        app.buttons["open-settings"].tap()
        app.buttons["add-domain"].tap()
        enterDomainNameAndSave(in: app, named: "Reading")
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        app.buttons["session-toggle"].tap()
        app.buttons["session-stop"].tap()
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 5))
        app.buttons["session-toggle"].tap()
        app.buttons["session-toggle"].tap()
        app.buttons["open-settings"].tap()
        app.buttons["open-sessions"].tap()
        XCTAssertTrue(app.navigationBars["Sessions"].waitForExistence(timeout: 5))
        let paused = historyRow(withStatus: "Paused", in: app)
        let completed = historyRow(withStatus: "Completed", in: app)
        XCTAssertTrue(paused.waitForExistence(timeout: 5))
        XCTAssertTrue(paused.label.contains("Reading"))
        XCTAssertTrue(completed.label.contains("Photography"))
        XCTAssertLessThan(paused.frame.minY, completed.frame.minY)
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'session-day-'")
        ).firstMatch.exists)
        keepScreenshot(of: app, name: "Session history grouped by day")
        let completedID = completed.identifier
        deleteHistoryRow(paused, in: app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: completedID).firstMatch.exists)
        app.navigationBars["Sessions"].buttons.element(boundBy: 0).tap()
        XCTAssertEqual(app.buttons["Reading"].value as? String, "waiting")
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Reading"].exists)
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")
        XCTAssertFalse(app.buttons["session-stop"].exists)
        app.buttons["session-toggle"].tap()
        app.buttons["open-settings"].tap()
        app.buttons["open-sessions"].tap()
        let running = historyRow(withStatus: "Started", in: app)
        XCTAssertTrue(running.waitForExistence(timeout: 5))
        XCTAssertTrue(running.label.contains("Reading"))
        keepScreenshot(of: app, name: "Running session in history")
        deleteHistoryRow(app.descendants(matching: .any).matching(identifier: completedID).firstMatch, in: app)
        XCTAssertTrue(running.exists)
        deleteHistoryRow(running, in: app)
        XCTAssertTrue(app.staticTexts["No sessions yet"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["session-toggle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")
        XCTAssertTrue(app.staticTexts["Reading"].exists)
        app.buttons["open-settings"].tap()
        app.buttons["open-sessions"].tap()
        XCTAssertTrue(app.staticTexts["No sessions yet"].waitForExistence(timeout: 5))
    }

    private func historyRow(withStatus status: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'session-row-' AND value == %@", status
        )).firstMatch
    }

    private func deleteHistoryRow(_ row: XCUIElement, in app: XCUIApplication) {
        let id = row.identifier
        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: id).firstMatch.waitForNonExistence(timeout: 5))
    }

    private func launchFreshApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launchEnvironment["DOMAIN_UI_TEST_STORE"] = UUID().uuidString
        app.launch()
        return app
    }

    private func addFirstDomain(in app: XCUIApplication, named name: String) {
        let add = app.buttons["add-first-domain"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        enterDomainNameAndSave(in: app, named: name)
        XCTAssertTrue(app.buttons["session-toggle"].waitForExistence(timeout: 5))
    }

    private func enterDomainNameAndSave(in app: XCUIApplication, named name: String) {
        let field = app.textFields["domain-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
        keepScreenshot(of: app, name: "First domain editor")
        app.buttons["save-domain"].tap()
    }

    private func assertHomeHeader(in app: XCUIApplication) {
        let settings = app.buttons["open-settings"]
        XCTAssertFalse(app.staticTexts["stick-wordmark"].exists)
        XCTAssertTrue(settings.isHittable)
        XCTAssertEqual(settings.label, "Settings")
        XCTAssertGreaterThanOrEqual(settings.frame.width, 44)
        XCTAssertGreaterThanOrEqual(settings.frame.height, 44)
        XCTAssertLessThanOrEqual(settings.frame.maxX, app.frame.maxX)
    }

    private func keepScreenshot(of app: XCUIApplication, name: String) {
        // Accessibility state can precede the final rendered control transition.
        // Give visual-review captures time to settle; behavioral assertions run first.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertWorldRenders(in app: XCUIApplication) {
        // A gray SpriteView can coexist with working SwiftUI navigation. Check
        // the central world area, away from the toolbar and bottom card.
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
        guard let image = screenshot.image.cgImage else {
            XCTFail("No screenshot image")
            return
        }

        var pixels = [UInt8](repeating: 0, count: 32 * 64 * 4)
        let rendered = pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(
                data: bytes.baseAddress, width: 32, height: 64,
                bitsPerComponent: 8, bytesPerRow: 32 * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: 32, height: 64))
            return true
        }
        XCTAssertTrue(rendered)

        var coloredPixels = 0
        for y in 16..<48 {
            for x in 8..<24 {
                let offset = (y * 32 + x) * 4
                let channels = pixels[offset..<(offset + 3)]
                if Int(channels.max()!) - Int(channels.min()!) > 20 {
                    coloredPixels += 1
                }
            }
        }
        // Pale clouds can cover most of this region. Detect the gray-rendering
        // regression without requiring a fixed fraction of saturated artwork.
        XCTAssertGreaterThan(coloredPixels, 0, "The world should render, rather than remain gray")
    }
}
