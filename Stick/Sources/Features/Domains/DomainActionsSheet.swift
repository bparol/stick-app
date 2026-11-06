import SwiftUI

struct DomainActionsSheet: View {
    let domainName: String
    let onSetCurrent: () throws -> Void
    @State private var saveError: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 20) {
            Text(domainName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Button("Set as current") {
                do {
                    try onSetCurrent()
                    dismiss()
                } catch {
                    saveError = (error as? DomainValidationError)?.errorDescription
                        ?? "Your choice wasn't saved. Please try again."
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.23, green: 0.34, blue: 0.23))
            .accessibilityIdentifier("set-current-domain")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .presentationDetents([typeSize.isAccessibilitySize ? .medium : .height(180)])
        .presentationDragIndicator(.visible)
        .alert("Couldn't set current domain", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError ?? "")
        }
    }
}
