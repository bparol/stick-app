import SwiftUI

struct DailyFocusCard: View {
    @Binding var hasCheckedIn: Bool

    private let ivory = Color(red: 0.99, green: 0.97, blue: 0.90)
    private let forest = Color(red: 0.23, green: 0.34, blue: 0.23)
    private let sage = Color(red: 0.49, green: 0.61, blue: 0.48)

    var body: some View {
        VStack(spacing: 0) {
            Text("Today you stick to:")
                .font(.system(size: 20, weight: .regular, design: .rounded))

            Text("Photography")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-0.5)
                .padding(.top, 6)

            Text("A little time counts.")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .padding(.top, 8)

            Button {
                hasCheckedIn = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 19, weight: .medium))
                        .opacity(hasCheckedIn ? 1 : 0)
                        .accessibilityHidden(true)
                    Text("I spent some time")
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                }
                .foregroundStyle(ivory)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(sage, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("I spent some time")
            .accessibilityValue(hasCheckedIn ? "Checked" : "Not checked")
            .accessibilityAddTraits(hasCheckedIn ? .isSelected : [])
            .accessibilityIdentifier("daily-check-in")
            .padding(.top, 18)
        }
        .foregroundStyle(forest)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(22)
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
    DailyFocusCard(hasCheckedIn: .constant(false)).padding()
}
