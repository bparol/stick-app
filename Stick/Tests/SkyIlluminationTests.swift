import Testing
@testable import Stick

struct SkyIlluminationTests {
    @Test func dawnAndDuskSpreadTheShadeChangeAcrossDaylight() throws {
        let map = try SkyIllumination.load()
        let visible = 390.0 / (2 * (844 / 2) * 1584 / 672)
        // At a 60-second cycle, three seconds into dawn must still be mostly dark.
        #expect(map.shadowAlpha(at: 0.05, dayFraction: 0.5, visibleFraction: visible) > 0.75)
        var previous = map.shadowAlpha(at: 0, dayFraction: 0.5, visibleFraction: visible)
        for step in 1...1000 {
            let next = map.shadowAlpha(at: Double(step) / 1000, dayFraction: 0.5, visibleFraction: visible)
            #expect(abs(next - previous) < 0.012)
            previous = next
        }
        for boundary in [0.0, 0.5, 1.0] {
            let before = map.shadowAlpha(at: boundary - 0.000001, dayFraction: 0.5, visibleFraction: visible)
            let after = map.shadowAlpha(at: boundary + 0.000001, dayFraction: 0.5, visibleFraction: visible)
            #expect(abs(after - before) < 0.0001)
        }
    }

    @Test func bundledArtworkHasGradualDuskAndDawn() throws {
        let map = try SkyIllumination.load()
        #expect(map.day.count == 128)
        #expect(map.night.count == 128)
        let visible = 390.0 / (2 * (844 / 2) * 1584 / 672)
        var dusk = 0.0
        var dawn = 1.0
        for step in 0...100 {
            let p = Double(step) / 400
            let nextDusk = map.shadowAlpha(at: 0.25 + p, dayFraction: 0.5, visibleFraction: visible)
            let nextDawn = map.shadowAlpha(at: p, dayFraction: 0.5, visibleFraction: visible)
            #expect(nextDusk >= dusk - 0.01)
            #expect(nextDawn <= dawn + 0.01)
            dusk = nextDusk
            dawn = nextDawn
        }
        #expect(dusk == 1)
        #expect(dawn == 0)
    }

    @Test func darkerArtworkProducesMoreShadowAtTheSameDayPosition() {
        let dark = SkyIllumination(day: [0.2, 0.3, 1, 0.3, 0.2], night: [0.1, 0.1])
        let light = SkyIllumination(day: [0.2, 0.8, 1, 0.8, 0.2], night: [0.1, 0.1])
        let darkAlpha = dark.shadowAlpha(at: 0.15, dayFraction: 0.5, visibleFraction: 0)
        let lightAlpha = light.shadowAlpha(at: 0.15, dayFraction: 0.5, visibleFraction: 0)
        #expect(darkAlpha > lightAlpha)
        #expect(darkAlpha < 1)
        #expect(lightAlpha > 0)
    }

    @Test func dayCenterIsClearAndNightRemainsDarkEvenWithBrightNightArtwork() {
        let map = SkyIllumination(day: [0.2, 1, 0.2], night: [1, 1, 1])
        #expect(map.shadowAlpha(at: 0.25, dayFraction: 0.5, visibleFraction: 0) == 0)
        for p in stride(from: 0.5, to: 1, by: 0.01) {
            #expect(map.shadowAlpha(at: p, dayFraction: 0.5, visibleFraction: 0) == 1)
        }
        #expect(map.shadowAlpha(at: 0, dayFraction: 0.5, visibleFraction: 0) == 1)
    }

    @Test func visibleBrightnessAveragesAcrossImageJoinsAndWraps() {
        let map = SkyIllumination(day: [1, 1], night: [0, 0])
        #expect(abs(map.meanBrightness(at: 0.5, dayFraction: 0.5, visibleFraction: 0.2) - 0.5) < 0.001)
        #expect(abs(map.meanBrightness(at: 0, dayFraction: 0.5, visibleFraction: 0.2) - 0.5) < 0.001)
        #expect(map.meanBrightness(at: 0.25, dayFraction: 0.5, visibleFraction: 0.2) == 1)
        #expect(map.meanBrightness(at: 0.75, dayFraction: 0.5, visibleFraction: 0.2) == 0)
    }

    @Test func flatArtworkStillHonorsTheRequestedDayAndNightEndpoints() {
        let map = SkyIllumination(day: [0.5, 0.5], night: [0.5, 0.5])
        #expect(map.shadowAlpha(at: 0.25, dayFraction: 0.5, visibleFraction: 0.1) == 0)
        #expect(map.shadowAlpha(at: 0, dayFraction: 0.5, visibleFraction: 0.1) == 1)
        #expect(map.shadowAlpha(at: 0.5, dayFraction: 0.5, visibleFraction: 0.1) == 1)
    }
}
