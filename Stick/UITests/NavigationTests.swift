import XCTest
import CoreGraphics

@MainActor
final class NavigationTests: XCTestCase {
    func testSettingsRoundTrip() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Today you stick to:"].waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.navigationBars["Stick"].waitForExistence(timeout: 5))
        assertWorldRenders(in: app)
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
