import Testing
@testable import Stick

@MainActor
struct AppModelTests {
    @Test func settingsRoundTripPreservesWorldAndItsState() {
        let model = AppModel()
        let original = model.meadow
        original.speed = 0.5

        model.path.append(.settings)
        #expect(model.meadow === original)
        model.path.removeLast()

        #expect(model.meadow === original)
        #expect(model.meadow.speed == 0.5)
    }

    @Test func windowsHaveIndependentWorlds() {
        let first = AppModel()
        let second = AppModel()
        #expect(first.meadow !== second.meadow)
    }

    @Test func worldIsReleasedWithItsOwner() {
        var model: AppModel? = AppModel()
        weak var world: MeadowScene?
        world = model?.meadow
        #expect(world != nil)

        model = nil

        #expect(world == nil)
    }
}
