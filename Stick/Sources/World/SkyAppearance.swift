import Observation

/// The small piece of scene presentation state consumed by the native header.
@MainActor
@Observable
final class SkyAppearance {
    var darkness = 0.0
}
