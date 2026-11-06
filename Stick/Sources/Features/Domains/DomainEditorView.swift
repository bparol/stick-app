import SwiftUI

struct DomainEditorView: View {
    let domain: DomainItem?
    let onSave: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameIsFocused: Bool
    @State private var name = ""
    @State private var saveError: String?

    init(domain: DomainItem? = nil, onSave: @escaping (String) throws -> Void) {
        self.domain = domain
        self.onSave = onSave
        _name = State(initialValue: domain?.name ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Guitar", text: $name)
                        .accessibilityIdentifier("domain-name")
                        .focused($nameIsFocused)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit { save() }
                }
            }
            .navigationTitle(domain == nil ? "Add a domain" : "Edit domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancel-domain")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(domain == nil ? "Add" : "Save") { save() }
                        .disabled(trimmedName.isEmpty)
                        .accessibilityIdentifier("save-domain")
                }
            }
            .alert("Couldn't save domain", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveError ?? "")
            }
            .task { nameIsFocused = true }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        do {
            try onSave(trimmedName)
            dismiss()
        } catch let error as DomainValidationError {
            saveError = error.localizedDescription
        } catch {
            saveError = "Your domain wasn't saved. Please try again."
        }
    }
}
