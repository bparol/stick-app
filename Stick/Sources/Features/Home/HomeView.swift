import SpriteKit
import SwiftUI

struct HomeView: View {
    let scene: MeadowScene
    let isPaused: Bool
    let session: FocusSession?
    let sessionStatus: SessionStatus
    let summary: SessionSummary?
    let domainName: String?
    let onAddFirstDomain: () -> Void
    let onToggleSession: () -> Void
    let onStopSession: () -> Void

    var body: some View {
        SpriteView(scene: scene)
            // Keep the view rendering its first frame; pause scene simulation
            // explicitly as activity and navigation change.
            .onChange(of: isPaused, initial: true) { _, paused in
                scene.isPaused = paused
            }
            .onChange(of: sessionStatus, initial: true) { _, status in
                scene.setMeditating(status == .started)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .safeAreaInset(edge: .top) {
                HomeHeader(appearance: scene.appearance)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if let summary {
                        Text("\(summary.domainName) · \(SessionTime.hoursMinutes(summary.totalSeconds)) total for \(summary.day)")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                            .accessibilityIdentifier("session-total-toast")
                    }
                    DailyFocusCard(
                        domainName: domainName, session: session, sessionStatus: sessionStatus,
                        isActive: !isPaused, onAddFirstDomain: onAddFirstDomain,
                        onToggleSession: onToggleSession, onStopSession: onStopSession
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .navigationTitle("Stick")
            .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
