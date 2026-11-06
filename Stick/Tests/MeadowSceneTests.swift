import SpriteKit
import Testing
import UIKit
@testable import Stick

@MainActor
struct MeadowSceneTests {
    @Test func characterLoadsAboveLandscapeAtTheDesignPosition() throws {
        let scene = MeadowScene()
        let character = try #require(scene.childNode(withName: "stick-character") as? SKSpriteNode)
        let artwork = try #require(UIImage(named: MeadowScene.characterImageNames[0]))
        let shadow = try #require(scene.childNode(withName: "landscape-shadow"))
        #expect(artwork.size.height > 100)
        #expect(character.texture != nil)
        #expect(character.zPosition > shadow.zPosition)
        #expect(abs(character.frame.midX - scene.size.width / 2) < 0.01)
        // Current layout: roughly 35% tall, feet around 68% down the screen.
        #expect((0.33...0.37).contains(character.frame.height / scene.size.height))
        #expect((0.30...0.34).contains(character.frame.minY / scene.size.height))
        #expect(abs(character.size.width / character.size.height
            - artwork.size.width / artwork.size.height) < 0.001)
    }

    @Test func characterKeepsItsFootPositionAndCurrentProportionsAfterResize() throws {
        let scene = MeadowScene()
        let character = try #require(scene.childNode(withName: "stick-character") as? SKSpriteNode)
        let originalFrame = character.frame
        let aspectRatio = character.size.width / character.size.height
        scene.update(0)
        scene.update(9)
        #expect(character.frame == originalFrame)
        #expect(!character.hasActions())
        for size in [CGSize(width: 375, height: 667), CGSize(width: 430, height: 932)] {
            scene.size = size
            #expect(abs(character.frame.midX - size.width / 2) < 0.01)
            #expect(abs(character.size.width / character.size.height - aspectRatio) < 0.001)
            #expect(abs(character.frame.minY - size.height * 0.32) < 0.01)
            #expect(character.frame.maxY < size.height * 0.7)
        }
        let resizedFrame = character.frame
        scene.update(9)
        #expect(character.frame == resizedFrame)
    }

    @Test func charactersRotateEveryTenSecondsInOrderAndWrap() throws {
        let scene = MeadowScene()
        let character = try #require(scene.childNode(withName: "stick-character") as? SKSpriteNode)
        #expect(MeadowScene.characterImageNames.count == 9)
        let firstTexture = character.texture
        scene.update(0)
        scene.update(9.99)
        #expect(character.texture === firstTexture)
        scene.update(10)
        #expect(character.texture !== firstTexture)
        for index in 1...9 {
            scene.update(Double(index * 10))
            let image = try #require(UIImage(named: MeadowScene.characterImageNames[index % 9]))
            let texture = try #require(character.texture)
            let expected = SKTexture(imageNamed: MeadowScene.characterImageNames[index % 9])
            #expect(UIImage(cgImage: texture.cgImage()).pngData()
                == UIImage(cgImage: expected.cgImage()).pngData())
            #expect(texture.size() == image.size)
            #expect(abs(character.size.width / character.size.height
                - image.size.width / image.size.height) < 0.001)
            #expect(abs(character.frame.minY - scene.size.height * 0.32) < 0.01)
        }
        #expect(UIImage(cgImage: try #require(character.texture).cgImage()).pngData()
            == UIImage(cgImage: try #require(firstTexture).cgImage()).pngData())
        #expect(scene.children.count == 5)
    }

    @Test func characterPreservesPartialIntervalAcrossPauseAndHandlesLargeSteps() throws {
        let scene = MeadowScene()
        let character = try #require(scene.childNode(withName: "stick-character") as? SKSpriteNode)
        let first = character.texture
        scene.update(0)
        scene.update(6)
        scene.isPaused = true
        scene.update(500)
        #expect(character.texture === first)
        scene.isPaused = false
        scene.update(1_000)
        scene.update(1_003)
        #expect(character.texture === first)
        scene.update(1_004)
        #expect(character.texture !== first)
        scene.update(1_084) // Finish the remaining eight poses and wrap.
        #expect(UIImage(cgImage: try #require(character.texture).cgImage()).pngData()
            == UIImage(cgImage: try #require(first).cgImage()).pngData())
        let wrapped = character.texture
        scene.update(1_083) // Negative deltas must not change the pose.
        #expect(character.texture === wrapped)
    }

    @Test func landscapeIsCenteredAtFullHeightAboveTheSky() throws {
        let scene = MeadowScene()
        let landscape = try #require(scene.childNode(withName: "landscape") as? SKSpriteNode)
        let texture = try #require(landscape.texture)
        let (day, night) = try skies(in: scene)
        #expect(texture.size().width > 100)
        #expect(abs(landscape.frame.height - scene.size.height) < 0.01)
        #expect(abs(landscape.frame.midX - scene.size.width / 2) < 0.01)
        #expect(abs(landscape.frame.midY - scene.size.height / 2) < 0.01)
        #expect(abs(landscape.size.width / landscape.size.height
            - texture.size().width / texture.size().height) < 0.001)
        #expect(landscape.zPosition > day.zPosition)
        #expect(landscape.zPosition > night.zPosition)
    }

    @Test func landscapeStaysStillWhileSkyMovesAndRecentersOnResize() throws {
        let scene = MeadowScene()
        let landscape = try #require(scene.childNode(withName: "landscape") as? SKSpriteNode)
        let (day, _) = try skies(in: scene)
        let originalFrame = landscape.frame
        scene.update(0)
        scene.update(10)
        #expect(landscape.frame == originalFrame)
        #expect(day.frame.minX < 0)
        scene.size = CGSize(width: 430, height: 932)
        #expect(abs(landscape.frame.height - 932) < 0.01)
        #expect(abs(landscape.frame.midX - 215) < 0.01)
        #expect(abs(landscape.frame.midY - 466) < 0.01)
        let resizedFrame = landscape.frame
        scene.update(20)
        #expect(landscape.frame == resizedFrame)
    }

    @Test func startsWithTwoUpperHalfSkiesAndDayIsCentered() throws {
        let scene = MeadowScene()
        let (day, night) = try skies(in: scene)
        #expect(scene.children.count == 5)
        #expect(abs(day.frame.midX - scene.size.width / 2) < 0.01)
        try expectCoverage(of: scene)
        for sprite in [day, night] {
            let texture = try #require(sprite.texture)
            #expect(texture.size().width > 100)
            #expect(sprite.frame.width >= scene.size.width)
            #expect(abs(sprite.frame.height - scene.size.height / 2) < 0.01)
            #expect(abs(sprite.size.width / sprite.size.height
                - texture.size().width / texture.size().height) < 0.001)
            #expect(abs(sprite.frame.midY - scene.size.height * 0.75) < 0.001)
        }
    }

    @Test func skiesMoveLeftTogetherAtTheSameSlowSpeed() throws {
        let scene = MeadowScene()
        let (day, night) = try skies(in: scene)
        let dayStart = day.frame.minX
        let nightStart = night.frame.minX
        scene.update(100)
        scene.update(101)
        let distance = (day.size.width + night.size.width) / scene.cycleDuration
        #expect(abs(day.frame.minX - dayStart + distance) < 0.01)
        #expect(abs(night.frame.minX - nightStart + distance) < 0.01)
        try expectCoverage(of: scene)
    }

    @Test func nightReplacesDayAndDayReturnsAfterAFullCycle() throws {
        let scene = MeadowScene()
        let (day, night) = try skies(in: scene)
        let nightArrival = scene.cycleDuration / 2
        scene.update(0)
        scene.update(nightArrival)
        #expect(abs(night.frame.midX - scene.size.width / 2) < 0.01)
        #expect(abs(day.frame.minX - night.frame.maxX) < 0.001)
        try expectCoverage(of: scene)
        scene.update(scene.cycleDuration)
        #expect(abs(day.frame.midX - scene.size.width / 2) < 0.01)
        try expectCoverage(of: scene)
    }

    @Test func repeatedWrapsNeverLeaveAGapOrAddNodes() throws {
        let scene = MeadowScene()
        scene.update(0)
        for time in stride(from: 1.0, through: 1_200.0, by: 7.0) {
            scene.update(time)
            try expectCoverage(of: scene)
            #expect(scene.children.count == 5)
        }
    }

    @Test func resumingDoesNotIncludeTimeSpentPaused() throws {
        let scene = MeadowScene()
        let (day, _) = try skies(in: scene)
        scene.update(0)
        scene.update(1)
        let beforePause = day.position
        scene.isPaused = true
        scene.isPaused = false
        scene.update(1_000)
        #expect(day.position == beforePause)
        scene.update(1_001)
        #expect(day.position.x < beforePause.x)
    }

    @Test func resizingPreservesProgressAndUpperHalfCoverage() throws {
        let scene = MeadowScene()
        scene.update(0)
        scene.update(75)
        scene.size = CGSize(width: 1_200, height: 400)
        try expectCoverage(of: scene)
        let (day, night) = try skies(in: scene)
        for sprite in [day, night] {
            #expect(abs(sprite.frame.height - 200) < 0.01)
            #expect(abs(sprite.frame.minY - 200) < 0.01)
        }
        let before = day.position
        scene.update(75)
        #expect(day.position == before)
        #expect(day.frame.minX != 0)
    }

    @Test func upperHalfKeepsFullImageProportionsAcrossPortraitAndWideResizes() throws {
        let scene = MeadowScene()
        scene.update(0)
        for size in [CGSize(width: 375, height: 667), CGSize(width: 430, height: 932),
                     CGSize(width: 1_200, height: 400), CGSize(width: 390, height: 844)] {
            scene.size = size
            let panels = skyPanels(in: scene)
            let (day, night) = try skies(in: scene)
            for panel in panels {
                let texture = try #require(panel.texture)
                #expect(abs(panel.size.width / panel.size.height - texture.size().width / texture.size().height) < 0.001)
                #expect(texture === day.texture || texture === night.texture)
            }
            #expect(panels.count == (size.width == 1_200 ? 4 : 2))
            for time in stride(from: 1.0, through: 180.0, by: 7.0) {
                scene.update(time)
                try expectCoverage(of: scene)
            }
        }
    }

    private func skyPanels(in scene: MeadowScene) -> [SKSpriteNode] {
        scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.hasPrefix("sky-") == true }
    }

    private func skies(in scene: MeadowScene) throws -> (SKSpriteNode, SKSpriteNode) {
        let day = try #require(scene.childNode(withName: "sky-day") as? SKSpriteNode)
        let night = try #require(scene.childNode(withName: "sky-night") as? SKSpriteNode)
        return (day, night)
    }

    private func expectCoverage(of scene: MeadowScene) throws {
        let panels = skyPanels(in: scene)
        let ordered = panels.map(\.frame).sorted { $0.minX < $1.minX }
        #expect(ordered.first!.minX <= 0.001)
        #expect(ordered.last!.maxX >= scene.size.width - 0.001)
        // SpriteKit stores geometry with limited precision; allow 0.01 point.
        for index in 1..<ordered.count {
            #expect(abs(ordered[index - 1].maxX - ordered[index].minX) < 0.01)
        }
        for frame in ordered {
            #expect(abs(frame.minY - scene.size.height / 2) < 0.01)
            #expect(abs(frame.maxY - scene.size.height) < 0.01)
        }
    }
}
