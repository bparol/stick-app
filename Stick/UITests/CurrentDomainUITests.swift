import XCTest
import CoreGraphics

@MainActor
final class CurrentDomainUITests: XCTestCase {
    func testWaitingLongPressSetsCurrentWithoutReorderingAndKeepsTapEditing() {
        let app = launchFreshApp()
        addFirstDomain(in: app, named: "Photography")
        app.buttons["open-settings"].tap()
        for name in ["Reading", "Guitar"] {
            app.buttons["add-domain"].tap()
            enterDomainNameAndSave(in: app, named: name)
        }
        app.buttons["Reading"].press(forDuration: 0.8)
        let select = app.buttons["set-current-domain"]
        XCTAssertTrue(select.waitForExistence(timeout: 5))
        XCTAssertTrue(select.isHittable)
        XCTAssertFalse(app.textFields["domain-name"].exists)
        keepScreenshot(of: app, name: "Set current domain sheet")
        select.tap()
        XCTAssertTrue(select.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Reading"].value as? String, "waiting")
        XCTAssertNotEqual(app.buttons["Photography"].value as? String, "waiting")
        XCTAssertLessThan(app.buttons["Photography"].frame.midY, app.buttons["Reading"].frame.midY)
        XCTAssertLessThan(app.buttons["Reading"].frame.midY, app.buttons["Guitar"].frame.midY)

        // Reordering must still work while waiting, when the hold action is available.
        let guitarID = app.buttons["Guitar"].identifier
        let photoID = app.buttons["Photography"].identifier
        app.buttons["edit-domains"].tap()
        let guitar = app.descendants(matching: .any).matching(identifier: guitarID).firstMatch
        let photo = app.descendants(matching: .any).matching(identifier: photoID).firstMatch
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: app.frame.maxX - 42, dy: guitar.frame.midY)
        )
        let end = app.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: app.frame.maxX - 42, dy: photo.frame.midY - 8)
        )
        start.press(forDuration: 0.8, thenDragTo: end)
        XCTAssertFalse(select.exists)
        app.buttons["edit-domains"].tap()
        XCTAssertLessThan(app.buttons["Guitar"].frame.midY, app.buttons["Photography"].frame.midY)
        XCTAssertEqual(app.buttons["Reading"].value as? String, "waiting")
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Reading"].exists)
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["session-toggle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Reading"].exists)
        XCTAssertEqual(app.buttons["session-toggle"].label, "Start")

        app.buttons["session-toggle"].tap()
        app.buttons["open-settings"].tap()
        app.buttons["Guitar"].press(forDuration: 0.8)
        XCTAssertFalse(select.exists)
        XCTAssertFalse(app.textFields["domain-name"].exists)
        app.buttons["Guitar"].tap()
        XCTAssertTrue(app.textFields["domain-name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["domain-name"].value as? String, "Guitar")
        app.buttons["cancel-domain"].tap()
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        app.buttons["session-toggle"].tap()
        app.buttons["open-settings"].tap()
        app.buttons["Guitar"].press(forDuration: 0.8)
        XCTAssertFalse(select.exists)
        XCTAssertFalse(app.textFields["domain-name"].exists)
        XCTAssertEqual(app.buttons["Reading"].value as? String, "paused")
    }

    func testDomainActionsSheetAtLargestAccessibilitySize() {
        let app = launchFreshApp(arguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])
        addFirstDomain(in: app, named: "Reading")
        app.buttons["open-settings"].tap()
        app.buttons["Reading"].press(forDuration: 0.8)
        let select = app.buttons["set-current-domain"]
        XCTAssertTrue(select.waitForExistence(timeout: 5))
        XCTAssertTrue(select.isHittable)
        XCTAssertLessThanOrEqual(select.frame.maxY, app.frame.maxY)
        keepScreenshot(of: app, name: "Set current domain sheet at largest text")
        select.tap() // Setting the existing current domain is a harmless no-op.
        XCTAssertTrue(select.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Reading"].value as? String, "waiting")
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

    private func keepScreenshot(of app: XCUIApplication, name: String) {
        // Accessibility state can precede the final rendered control transition.
        // Give visual-review captures time to settle; behavioral assertions run first.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}
