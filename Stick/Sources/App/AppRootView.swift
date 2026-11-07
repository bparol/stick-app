import SwiftUI

struct AppRootView: View {
    @State private var model = AppModel()
    @State private var domainSheet: DomainSheetRequest?
    @State private var sessionError: String?
    @State private var summary: SessionSummary?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $model.path) {
            HomeView(
                scene: model.meadow,
                isPaused: scenePhase != .active || !model.path.isEmpty || domainSheet != nil,
                session: model.activeSession,
                sessionStatus: model.sessionStatus,
                summary: summary,
                domainName: model.currentDomain?.name,
                onAddFirstDomain: { domainSheet = .add },
                onToggleSession: toggleSession,
                onStopSession: stopSession
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView(
                        domains: model.domains,
                        currentDomainID: model.currentDomain?.id,
                        sessionStatus: model.sessionStatus,
                        onAddDomain: { domainSheet = .add },
                        onEditDomain: { domain in
                            guard domainSheet == nil else { return }
                            domainSheet = .edit(domain)
                        },
                        onLongPressDomain: { domain in
                            guard model.sessionStatus == .waiting else { return }
                            domainSheet = .actions(domain)
                        },
                        onDeleteDomains: model.deleteDomains,
                        onReorderDomains: model.reorderDomains
                    )
                case .sessions:
                    SessionsView(
                        days: model.sessionDays,
                        domainName: model.domainName,
                        onDeleteSessions: { ids in
                            try model.deleteSessions(ids: ids)
                            summary = nil
                        },
                        onUpdateDuration: { id, duration in
                            try model.updateSessionDuration(id: id, duration: duration)
                            summary = nil
                        }
                    )
                }
            }
        }
        .task(id: summary?.id) {
            guard summary != nil else { return }
            do { try await Task.sleep(for: .seconds(6)) }
            catch { return }
            summary = nil
        }
        .sheet(item: $domainSheet) { request in
            switch request {
            case .add:
                DomainEditorView(domain: nil) { try model.addDomain(named: $0) }
            case .edit(let domain):
                DomainEditorView(domain: domain) { try model.renameDomain(id: domain.id, named: $0) }
            case .actions(let domain):
                DomainActionsSheet(domainName: domain.name) {
                    try model.setCurrentDomain(id: domain.id)
                    summary = nil
                }
            }
        }
        .alert(model.loadError == nil ? "Couldn't save session" : "Couldn't load domains", isPresented: Binding(
            get: { model.loadError != nil || sessionError != nil },
            set: {
                if !$0 {
                    model.loadError = nil
                    sessionError = nil
                }
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(model.loadError ?? sessionError ?? "")
        }
    }

    private func toggleSession() {
        do {
            if model.sessionStatus == .started { try model.pauseSession() }
            else { try model.startSession() }
            summary = nil
        } catch {
            sessionError = "Your session wasn't saved. Please try again."
        }
    }

    private func stopSession() {
        do { summary = try model.stopSession() }
        catch { sessionError = "Your session wasn't saved. Please try again." }
    }

}

#Preview {
    AppRootView()
}

private enum DomainSheetRequest: Identifiable {
    case add
    case edit(DomainItem)
    case actions(DomainItem)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let domain): "edit-\(domain.id)"
        case .actions(let domain): "actions-\(domain.id)"
        }
    }
}
