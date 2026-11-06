import SwiftUI

struct SettingsView: View {
    let domains: [DomainItem]
    let currentDomainID: String?
    let sessionStatus: SessionStatus
    let onAddDomain: () -> Void
    let onEditDomain: (DomainItem) -> Void
    let onLongPressDomain: (DomainItem) -> Void
    let onDeleteDomains: (Set<String>) throws -> Void
    let onReorderDomains: ([String]) throws -> Void
    @State private var saveError: String?
    @State private var editMode = EditMode.inactive

    var body: some View {
        Form {
            Section {
                if domains.isEmpty {
                    Text("Choose what you want to make time for.")
                }
                ForEach(domains) { domain in
                    Button { onEditDomain(domain) } label: {
                        HStack {
                            Text(domain.name).foregroundStyle(.primary)
                            Spacer()
                            if domain.id == currentDomainID {
                                Text(sessionStatus.rawValue)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .simultaneousGesture(
                        LongPressGesture().onEnded { _ in
                            guard sessionStatus == .waiting else { return }
                            onLongPressDomain(domain)
                        },
                        isEnabled: editMode != .active
                    )
                    .moveDisabled(editMode != .active)
                    .accessibilityLabel(domain.name)
                    .accessibilityValue(domain.id == currentDomainID ? sessionStatus.rawValue : "")
                    .accessibilityIdentifier("domain-row-\(domain.id)")
                }
                .onDelete { offsets in
                    save { try onDeleteDomains(Set(offsets.map { domains[$0].id })) }
                }
                .onMove { offsets, destination in
                    var reordered = domains
                    reordered.move(fromOffsets: offsets, toOffset: destination)
                    save { try onReorderDomains(reordered.map(\.id)) }
                }
                Button("Add a domain", systemImage: "plus", action: onAddDomain)
                    .accessibilityIdentifier("add-domain")
            } header: {
                Text("My domains")
            } footer: {
                Text("Tap a domain to edit it. While waiting, touch and hold a domain to set it as current. Use Edit to delete or reorder. Stop completes the current domain and moves to the next in this order.")
            }
            Section {
                NavigationLink("Sessions", value: AppRoute.sessions)
                    .accessibilityIdentifier("open-sessions")
            }
            Section("Daily reminder") {
                Text("Reminder preferences are coming next.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            EditButton()
                .disabled(domains.isEmpty)
                .accessibilityIdentifier("edit-domains")
        }
        .environment(\.editMode, $editMode)
        .alert("Couldn't save changes", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func save(_ action: () throws -> Void) {
        do { try action() }
        catch { saveError = "Your changes weren't saved. Please try again." }
    }
}
