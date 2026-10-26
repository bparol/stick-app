import SwiftUI

struct AppRootView: View {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $model.path) {
            HomeView(
                scene: model.meadow,
                isPaused: scenePhase != .active || !model.path.isEmpty
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    AppRootView()
}
