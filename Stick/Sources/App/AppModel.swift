import Observation

enum AppRoute: Hashable {
    case settings
}

@MainActor
@Observable
final class AppModel {
    var path: [AppRoute] = []

    // Rendering state is not observable app data. Allocate it only on first use.
    @ObservationIgnored
    lazy var meadow = MeadowScene()
}
