import SwiftUI

/// Only this subview reads changing sky appearance; the world retains its owner.
struct HomeHeader: View {
    let appearance: SkyAppearance

    var body: some View {
        let tint = HomeHeaderTint(darkness: appearance.darkness)
        HStack {
            StickWordmark(tint: tint.wordmark)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Spacer(minLength: 16)
            NavigationLink(value: AppRoute.settings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(tint.settings)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("open-settings")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

struct HomeHeaderTint {
    let darkness: Double

    // Preserve each original daytime color; both approach the same muted sage.
    var wordmark: Color { blend(red: 0.20, green: 0.35, blue: 0.23) }
    var settings: Color { blend(red: 0.32, green: 0.41, blue: 0.27) }

    private func blend(red: Double, green: Double, blue: Double) -> Color {
        let t = min(1, max(0, darkness))
        return Color(
            red: red + (0.50 - red) * t,
            green: green + (0.65 - green) * t,
            blue: blue + (0.42 - blue) * t
        )
    }
}
