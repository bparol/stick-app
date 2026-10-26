import SpriteKit
import Testing
@testable import Stick

@MainActor
struct MeadowSceneTests {
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

    @Test func startsWithTwoSkiesLandscapeAndShadowAndDayIsCentered() throws {
        let scene = MeadowScene()
        let (day, night) = try skies(in: scene)
        #expect(scene.children.count == 4)
        #expect(abs(day.frame.midX - scene.size.width / 2) < 0.01)
        try expectCoverage(of: scene)
        for sprite in [day, night] {
            let texture = try #require(sprite.texture)
            #expect(texture.size().width > 100)
            #expect(sprite.frame.width >= scene.size.width)
            #expect(sprite.frame.height >= scene.size.height)
            #expect(abs(sprite.size.width / sprite.size.height
                - texture.size().width / texture.size().height) < 0.001)
            #expect(abs(sprite.frame.midY - scene.size.height / 2) < 0.001)
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
            #expect(scene.children.count == 4)
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

    @Test func resizingPreservesProgressAndAspectFillCoverage() throws {
        let scene = MeadowScene()
        scene.update(0)
        scene.update(75)
        scene.size = CGSize(width: 1_200, height: 400)
        try expectCoverage(of: scene)
        let (day, night) = try skies(in: scene)
        for sprite in [day, night] {
            #expect(sprite.frame.height >= 400)
            #expect(sprite.frame.width >= 1_200)
        }
        let before = day.position
        scene.update(75)
        #expect(day.position == before)
        #expect(day.frame.minX != 0)
    }

    private func skies(in scene: MeadowScene) throws -> (SKSpriteNode, SKSpriteNode) {
        let day = try #require(scene.childNode(withName: "sky-day") as? SKSpriteNode)
        let night = try #require(scene.childNode(withName: "sky-night") as? SKSpriteNode)
        return (day, night)
    }

    private func expectCoverage(of scene: MeadowScene) throws {
        let (day, night) = try skies(in: scene)
        let ordered = [day.frame, night.frame].sorted { $0.minX < $1.minX }
        #expect(ordered[0].minX <= 0.001)
        #expect(ordered[1].maxX >= scene.size.width - 0.001)
        // SpriteKit stores geometry with limited precision; allow 0.01 point.
        #expect(abs(ordered[0].maxX - ordered[1].minX) < 0.01)
    }
}
