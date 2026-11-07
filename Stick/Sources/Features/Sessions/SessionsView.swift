import SwiftUI

struct SessionsView: View {
    let days: [SessionDayGroup]
    let domainName: (FocusSession) -> String
    let onDeleteSessions: (Set<String>) throws -> Void
    let onUpdateDuration: (String, TimeInterval) throws -> Void
    @State private var editingSession: FocusSession?
    @State private var saveError: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            ForEach(days) { day in
                Section {
                    ForEach(day.sessions) { session in
                        SessionHistoryRow(
                            session: session, domainName: domainName(session),
                            isActive: scenePhase == .active,
                            onEditDuration: { editingSession = session }
                        )
                    }
                    .onDelete { offsets in
                        let ids = Set(offsets.map { day.sessions[$0].id })
                        do { try onDeleteSessions(ids) }
                        catch { saveError = "Your session wasn't deleted. Please try again." }
                    }
                } header: {
                    // Use the recorded attribution day, not a date derived from
                    // the latest resume/completion or the current time zone.
                    Text(day.day).accessibilityIdentifier("session-day-\(day.day)")
                }
            }
        }
        .overlay {
            if days.isEmpty {
                ContentUnavailableView(
                    "No sessions yet", systemImage: "clock",
                    description: Text("Sessions appear when you start a domain.")
                )
                .accessibilityIdentifier("empty-sessions")
            }
        }
        .sheet(item: $editingSession) { session in
            SessionDurationEditorView(session: session) { duration in
                try onUpdateDuration(session.id, duration)
            }
        }
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            EditButton().disabled(days.isEmpty)
                .accessibilityIdentifier("edit-sessions")
        }
        .alert("Couldn't delete session", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError ?? "")
        }
    }
}

private struct SessionHistoryRow: View {
    let session: FocusSession
    let domainName: String
    let isActive: Bool
    let onEditDuration: () -> Void

    private var status: String {
        if session.completedAt != nil { return "Completed" }
        return session.isRunning ? "Started" : "Paused"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(domainName).font(.headline).lineLimit(2)
                HStack(spacing: 5) {
                    Text(session.startedAt, style: .time)
                    Text("· \(status)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: onEditDuration) {
                Group {
                    if session.isRunning {
                        TimelineView(.animation(minimumInterval: 1, paused: !isActive)) { context in
                            duration(at: context.date)
                        }
                        .fixedSize()
                    } else {
                        duration(at: session.completedAt ?? session.startedAt)
                    }
                }
                .frame(minWidth: 60, minHeight: 44, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit duration for \(domainName)")
            .accessibilityIdentifier("edit-session-duration-\(session.id)")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(domainName)
        .accessibilityValue(status)
        .accessibilityIdentifier("session-row-\(session.id)")
    }

    private func duration(at date: Date) -> some View {
        Text(SessionTime.hoursMinutes(session.elapsed(at: date)))
            .monospacedDigit()
    }
}
