import SpriteKit
import SwiftUI

struct HomeView: View {
    let scene: MeadowScene
    let isPaused: Bool

    var body: some View {
        SpriteView(scene: scene)
            // Keep the view rendering its first frame; pause scene simulation
            // explicitly as activity and navigation change.
            .onChange(of: isPaused, initial: true) { _, paused in
                scene.isPaused = paused
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Text("Today you stick to:")
                        .font(.headline)
                    Text("A little time counts.")
                        .font(.title2.bold())
                    Text("Your interests will appear here.")
                        .font(.subheadline)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding()
            }
            .navigationTitle("Stick")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: AppRoute.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("open-settings")
                }
            }
    }
}
