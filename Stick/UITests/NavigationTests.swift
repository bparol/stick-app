import XCTest
import CoreGraphics

@MainActor
final class NavigationTests: XCTestCase {
    func testDailyCheckInStaysCheckedAfterTappingAndReturningFromSettings() {
        let app = XCUIApplication()
        app.launch()

        let checkIn = app.buttons["daily-check-in"]
        XCTAssertTrue(checkIn.waitForExistence(timeout: 10))
        XCTAssertEqual(checkIn.value as? String, "Not checked")
        XCTAssertFalse(checkIn.isSelected)
        keepScreenshot(of: app, name: "Daily card before check-in")

        checkIn.tap()
        XCTAssertEqual(checkIn.value as? String, "Checked")
        XCTAssertTrue(checkIn.isSelected)
        keepScreenshot(of: app, name: "Daily card after check-in")

        // This is an acknowledgement, so another tap must not undo it.
        checkIn.tap()
        XCTAssertTrue(checkIn.isSelected)
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(checkIn.waitForExistence(timeout: 5))
        XCTAssertTrue(checkIn.isSelected)
        XCTAssertEqual(checkIn.value as? String, "Checked")
    }

    func testSettingsRoundTrip() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Today you stick to:"].waitForExistence(timeout: 10))
        assertHomeHeader(in: app)
        assertWorldRenders(in: app)
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Choose what you want to make time for."].exists)

        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Today you stick to:"].waitForExistence(timeout: 5))

        // A second visit catches stale paths or a broken native back binding.
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Today you stick to:"].waitForExistence(timeout: 5))
        assertHomeHeader(in: app)
        assertWorldRenders(in: app)
    }

    func testHeaderAtLargestAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Today you stick to:"].waitForExistence(timeout: 10))
        assertHomeHeader(in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertHomeHeader(in app: XCUIApplication) {
        let wordmark = app.staticTexts["stick-wordmark"]
        let settings = app.buttons["open-settings"]
        XCTAssertTrue(wordmark.exists)
        XCTAssertEqual(wordmark.label, "Stick")
        XCTAssertTrue(settings.isHittable)
        XCTAssertEqual(settings.label, "Settings")
        XCTAssertGreaterThanOrEqual(settings.frame.width, 44)
        XCTAssertGreaterThanOrEqual(settings.frame.height, 44)
        XCTAssertLessThan(wordmark.frame.maxX, settings.frame.minX)
        XCTAssertLessThan(abs(wordmark.frame.midY - settings.frame.midY), 4)
        XCTAssertGreaterThanOrEqual(wordmark.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(settings.frame.maxX, app.frame.maxX)
    }

    private func keepScreenshot(of app: XCUIApplication, name: String) {
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
