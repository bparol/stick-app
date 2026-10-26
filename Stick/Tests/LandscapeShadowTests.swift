import SpriteKit
import Testing
@testable import Stick

@MainActor
struct LandscapeShadowTests {
    @Test func shadowUsesLandscapeAlphaAndFadesFromTopToBottom() throws {
        let scene = MeadowScene()
        let shadow = try shadow(in: scene)
        let landscape = try #require(scene.childNode(withName: "landscape") as? SKSpriteNode)
        let source = try rgba(try #require(landscape.texture).cgImage())
        let masked = try rgba(try #require(shadow.texture).cgImage())
        #expect(source.width == masked.width)
        #expect(source.height == masked.height)
        var transparentSamples = 0
        var opaqueSamples = 0
        for y in stride(from: 0, to: source.height, by: 23) {
            for x in stride(from: 0, to: source.width, by: 29) {
                let offset = (y * source.width + x) * 4
                let sourceAlpha = Int(source.bytes[offset + 3])
                let actualAlpha = Int(masked.bytes[offset + 3])
                let expectedAlpha = Double(sourceAlpha) * (1 - (Double(y) + 0.5) / Double(source.height))
                #expect(abs(Double(actualAlpha) - expectedAlpha) < 3)
                #expect(masked.bytes[offset] == 0)
                #expect(masked.bytes[offset + 1] == 0)
                #expect(masked.bytes[offset + 2] == 0)
                if sourceAlpha == 0 {
                    transparentSamples += 1
                    #expect(actualAlpha == 0)
                } else {
                    opaqueSamples += 1
                }
            }
        }
        #expect(transparentSamples > 0)
        #expect(opaqueSamples > 0)
        #expect(masked.bytes[3] > 250)
        #expect(masked.bytes[((source.height - 1) * source.width) * 4 + 3] == 0)
    }

    @Test func startsAtDayCenterAndShadowStaysFullThroughoutNight() throws {
        let scene = MeadowScene()
        let shadow = try shadow(in: scene)
        let day = try #require(scene.childNode(withName: "sky-day") as? SKSpriteNode)
        let night = try #require(scene.childNode(withName: "sky-night") as? SKSpriteNode)
        let dayDuration = scene.cycleDuration * day.size.width / (day.size.width + night.size.width)
        let nightDuration = scene.cycleDuration - dayDuration
        scene.update(0)
        #expect(abs(shadow.alpha) < 0.001)
        scene.update(dayDuration / 2)
        #expect(abs(shadow.alpha - 1) < 0.001)
        for fraction in [0.1, 0.25, 0.5, 0.75, 0.9, 1.0] {
            scene.update(dayDuration / 2 + fraction * nightDuration)
            #expect(abs(shadow.alpha - 1) < 0.001)
        }
        scene.update(scene.cycleDuration)
        #expect(abs(shadow.alpha) < 0.001)
    }

    @Test func shadowFollowsLandscapeLayoutAndKeepsItsTextureAcrossResizeAndPause() throws {
        let scene = MeadowScene()
        let shadow = try shadow(in: scene)
        let landscape = try #require(scene.childNode(withName: "landscape") as? SKSpriteNode)
        let texture = try #require(shadow.texture)
        #expect(shadow.frame == landscape.frame)
        #expect(shadow.zPosition > landscape.zPosition)
        scene.update(0)
        scene.update(10)
        scene.size = CGSize(width: 430, height: 932)
        #expect(shadow.frame == landscape.frame)
        #expect(shadow.texture === texture)
        #expect((0...1).contains(shadow.alpha))
        let resizedAlpha = shadow.alpha
        scene.isPaused = true
        scene.isPaused = false
        scene.update(1_000)
        #expect(shadow.alpha == resizedAlpha)
    }

    private func shadow(in scene: MeadowScene) throws -> SKSpriteNode {
        try #require(scene.childNode(withName: "landscape-shadow") as? SKSpriteNode)
    }

    private func rgba(_ image: CGImage) throws -> (bytes: [UInt8], width: Int, height: Int) {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let rendered = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        try #require(rendered)
        return (bytes, image.width, image.height)
    }
}
