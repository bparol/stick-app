import SpriteKit
import SwiftUI

struct HomeView: View {
    let scene: MeadowScene
    let isPaused: Bool
    @Binding var hasCheckedIn: Bool

    var body: some View {
        SpriteView(scene: scene)
            // Keep the view rendering its first frame; pause scene simulation
            // explicitly as activity and navigation change.
            .onChange(of: isPaused, initial: true) { _, paused in
                scene.isPaused = paused
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .safeAreaInset(edge: .top) {
                HomeHeader(appearance: scene.appearance)
            }
            .safeAreaInset(edge: .bottom) {
                DailyFocusCard(hasCheckedIn: $hasCheckedIn)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Stick")
            .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
