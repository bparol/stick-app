import Foundation

/// Offline column brightness profiles; frame updates only interpolate small arrays.
struct SkyIllumination: Decodable {
    let day: [Double]
    let night: [Double]

    static func load() throws -> Self {
        guard let url = Bundle.main.url(forResource: "sky-illumination", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let map = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard [map.day, map.night].allSatisfy({ profile in
            profile.count >= 2 && profile.allSatisfy { $0.isFinite && (0...1).contains($0) }
        }) else { throw CocoaError(.fileReadCorruptFile) }
        return map
    }

    func shadowAlpha(at progress: Double, dayFraction: Double, visibleFraction: Double) -> Double {
        let p = wrapped(progress)
        // Bright painted clouds in the night image must not lift the night shade.
        guard p < dayFraction else { return 1 }
        let center = dayFraction / 2
        let centerLight = meanBrightness(at: center, dayFraction: dayFraction, visibleFraction: visibleFraction)
        let edgeLight = meanBrightness(
            at: p < center ? 0 : dayFraction,
            dayFraction: dayFraction, visibleFraction: visibleFraction
        )
        let contrast = centerLight - edgeLight
        let darkness: Double
        if contrast > 0.000001 {
            let light = meanBrightness(at: p, dayFraction: dayFraction, visibleFraction: visibleFraction)
            darkness = (centerLight - light) / contrast
        } else {
            // A flat/reversed profile has no useful daylight contrast to normalize.
            darkness = abs(p / dayFraction - 0.5) * 2
        }
        let t = min(1, max(0, darkness))
        return t * t * (3 - 2 * t)
    }

    func meanBrightness(at progress: Double, dayFraction: Double, visibleFraction: Double) -> Double {
        var total = 0.0
        // Average the actual visible width, including both images at a join.
        for i in 0..<32 {
            let p = wrapped(progress + (Double(i) / 32 + 0.5 / 32 - 0.5) * visibleFraction)
            if p < dayFraction {
                total += sample(day, at: p / dayFraction)
            } else {
                total += sample(night, at: (p - dayFraction) / (1 - dayFraction))
            }
        }
        return total / 32
    }

    private func sample(_ profile: [Double], at position: Double) -> Double {
        let index = min(Double(profile.count - 1), max(0, position * Double(profile.count) - 0.5))
        let lower = Int(index)
        let upper = min(profile.count - 1, lower + 1)
        return profile[lower] + (profile[upper] - profile[lower]) * (index - Double(lower))
    }

    private func wrapped(_ value: Double) -> Double {
        value - floor(value)
    }
}
