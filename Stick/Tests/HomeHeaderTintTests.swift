import SpriteKit
import SwiftUI
import Testing
@testable import Stick

@MainActor
struct HomeHeaderTintTests {
    @Test func fullBrightnessPreservesBothOriginalColors() {
        expect(HomeHeaderTint(darkness: 0).wordmark, matches: [0.20, 0.35, 0.23])
        expect(HomeHeaderTint(darkness: 0).settings, matches: [0.32, 0.41, 0.27])
    }

    @Test func nightIsLighterAndIntermediateTintIsBetweenEndpoints() {
        expect(HomeHeaderTint(darkness: 1).wordmark, matches: [0.50, 0.65, 0.42])
        expect(HomeHeaderTint(darkness: 1).settings, matches: [0.50, 0.65, 0.42])
        expect(HomeHeaderTint(darkness: 0.5).wordmark, matches: [0.35, 0.50, 0.325])
        expect(HomeHeaderTint(darkness: 0.5).settings, matches: [0.41, 0.53, 0.345])
    }

    @Test func tintTracksMeasuredLightRatherThanOnlyTheClock() {
        let bright = SkyIllumination(day: [0.2, 0.9, 1, 0.9, 0.2], night: [0.1, 0.1])
        let dark = SkyIllumination(day: [0.2, 0.3, 1, 0.3, 0.2], night: [0.1, 0.1])
        let p = 0.15
        #expect(dark.headerDarkness(at: p, dayFraction: 0.5, visibleFraction: 0)
            > bright.headerDarkness(at: p, dayFraction: 0.5, visibleFraction: 0))
        let flat = SkyIllumination(day: [0.5, 0.5], night: [0.5, 0.5])
        #expect(flat.headerDarkness(at: 0.75, dayFraction: 0.5, visibleFraction: 0.1) == 0)
    }

    @Test func headerLightFollowsVisibleJoinsAndWrapsContinuously() {
        let map = SkyIllumination(day: [1, 1], night: [0, 0])
        #expect(map.headerDarkness(at: 0.25, dayFraction: 0.5, visibleFraction: 0.2) == 0)
        #expect(map.headerDarkness(at: 0.75, dayFraction: 0.5, visibleFraction: 0.2) == 1)
        #expect(abs(map.headerDarkness(at: 0.5, dayFraction: 0.5, visibleFraction: 0.2) - 0.5) < 0.001)
        #expect(abs(map.headerDarkness(at: 0, dayFraction: 0.5, visibleFraction: 0.2) - 0.5) < 0.001)
        let before = map.headerDarkness(at: 0.9999, dayFraction: 0.5, visibleFraction: 0.2)
        let after = map.headerDarkness(at: 0.0001, dayFraction: 0.5, visibleFraction: 0.2)
        #expect(abs(before - after) < 0.01)
    }

    @Test func scenePublishesLightInSyncWithMotionResizeAndPause() throws {
        let scene = MeadowScene()
        let appearance = scene.appearance
        let map = try SkyIllumination.load()
        #expect(appearance.darkness == 0)
        scene.update(0)
        scene.update(scene.cycleDuration / 2)
        #expect(appearance.darkness > 0.99)
        scene.update(scene.cycleDuration * 0.7)
        scene.size = CGSize(width: 430, height: 932)
        let day = try #require(scene.childNode(withName: "sky-day") as? SKSpriteNode)
        let night = try #require(scene.childNode(withName: "sky-night") as? SKSpriteNode)
        let width = day.size.width + night.size.width
        let expected = map.headerDarkness(
            at: 0.95, dayFraction: Double(day.size.width / width),
            visibleFraction: Double(scene.size.width / width)
        )
        #expect(abs(appearance.darkness - expected) < 0.000001)
        let pausedTint = appearance.darkness
        scene.isPaused = true
        scene.update(10_000)
        #expect(appearance.darkness == pausedTint)
        scene.isPaused = false
        scene.update(20_000)
        #expect(appearance.darkness == pausedTint)
        #expect(scene.appearance === appearance)
    }

    private func expect(_ color: Color, matches expected: [Double]) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        for (actual, expected) in zip([red, green, blue], expected) {
            #expect(abs(Double(actual) - expected) < 0.00001)
        }
        #expect(alpha == 1)
    }
}
