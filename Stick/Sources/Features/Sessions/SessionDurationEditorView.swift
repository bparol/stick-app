import SwiftUI

struct SessionDurationEditorView: View {
    let onSave: (TimeInterval) throws -> Void
    private let maximumHours: Int
    @State private var hours: Int
    @State private var minutes: Int
    @State private var saveError: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(session: FocusSession, onSave: @escaping (TimeInterval) throws -> Void) {
        let totalMinutes = Int(session.elapsed(at: Date()) / 60)
        maximumHours = max(999, totalMinutes / 60)
        _hours = State(initialValue: totalMinutes / 60)
        _minutes = State(initialValue: totalMinutes % 60)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                VStack {
                    Text("Hours").font(.headline)
                    Picker("Hours", selection: $hours) {
                        ForEach(0...maximumHours, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .accessibilityIdentifier("duration-hours")
                }
                VStack {
                    Text("Minutes").font(.headline)
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .accessibilityIdentifier("duration-minutes")
                }
            }
            .pickerStyle(.wheel)
            .padding()
            .navigationTitle("Session duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancel-session-duration")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("save-session-duration")
                }
            }
            .alert("Couldn't save duration", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveError ?? "")
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        do {
            try onSave(TimeInterval(hours * 3_600 + minutes * 60))
            dismiss()
        } catch let error as DomainValidationError {
            saveError = error.localizedDescription
        } catch {
            saveError = "Your session duration wasn't saved. Please try again."
        }
    }
}
