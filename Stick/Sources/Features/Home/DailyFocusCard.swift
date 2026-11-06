import SwiftUI

struct DailyFocusCard: View {
    let domainName: String?
    let session: FocusSession?
    let sessionStatus: SessionStatus
    let isActive: Bool
    let onAddFirstDomain: () -> Void
    let onToggleSession: () -> Void
    let onStopSession: () -> Void

    private let ivory = Color(red: 0.99, green: 0.97, blue: 0.90)
    private let forest = Color(red: 0.23, green: 0.34, blue: 0.23)

    var body: some View {
        VStack(spacing: 0) {
            Text(
                domainName == nil
                ? "What domain will you focus on today?"
                : "Everything moves, you stick:"
            )
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .accessibilityIdentifier("focus-card-prompt")

            if let domainName {
                Text(domainName)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .tracking(-0.5)
                    .padding(.top, 6)
            } else {
                DomainExamplesCarousel(isActive: isActive)
                    .padding(.top, 6)
            }

            if domainName == nil {
                Button(action: onAddFirstDomain) {
                    HStack(spacing: 10) {
                        Text("Add your first domain")
                        TwigMark().frame(width: 14.3, height: 26).accessibilityHidden(true)
                    }
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay { Capsule().strokeBorder(forest, lineWidth: 1.5) }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("add-first-domain")
                .padding(.top, 18)
            } else {
                HStack(spacing: 12) {
                    Button(action: onToggleSession) {
                        HStack(spacing: 10) {
                            Image(systemName: sessionStatus == .started ? "pause.fill" : "play.fill")
                                .accessibilityHidden(true)
                            if sessionStatus == .started {
                                // Refresh only the running text. Controls stay outside
                                // the timeline, including while updates are paused.
                                TimelineView(.animation(minimumInterval: 1, paused: !isActive)) { context in
                                    Text("Pause (\(SessionTime.hoursMinutes(session?.elapsed(at: context.date) ?? 0)))")
                                        .monospacedDigit()
                                }
                                .fixedSize()
                            } else {
                                Text(sessionStatus == .paused ? "Continue" : "Start")
                            }
                        }
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(forest, in: Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(sessionStatus.rawValue)
                    .accessibilityIdentifier("session-toggle")
                    if sessionStatus != .waiting {
                        Button(action: onStopSession) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 19, weight: .medium))
                                .frame(width: 50, height: 50)
                                .background(forest, in: Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Stop")
                        .accessibilityIdentifier("session-stop")
                    }
                }
                .foregroundStyle(ivory)
                .padding(.top, 18)
            }
        }
        .foregroundStyle(forest)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding([.leading, .trailing, .bottom], 22)
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(ivory)
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
        }
        // The design uses fixed point sizes, including at accessibility sizes.
        .dynamicTypeSize(.large)
    }

}

#Preview {
    DailyFocusCard(
        domainName: nil, session: nil, sessionStatus: .waiting, isActive: true,
        onAddFirstDomain: {}, onToggleSession: {}, onStopSession: {}
    ).padding()
}
