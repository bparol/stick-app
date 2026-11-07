import Foundation
import Observation

enum AppRoute: Hashable {
    case settings
    case sessions
}

@MainActor
@Observable
final class AppModel {
    var path: [AppRoute] = []
    private var state = DomainState()
    var domains: [DomainItem] { state.domains }
    var sessions: [FocusSession] { state.sessions }
    var sessionDays: [SessionDayGroup] {
        Dictionary(grouping: sessions, by: \.day).map { day, records in
            SessionDayGroup(day: day, sessions: records.sorted {
                $0.startedAt == $1.startedAt ? $0.id < $1.id : $0.startedAt > $1.startedAt
            })
        }.sorted { $0.day > $1.day }
    }
    var currentDomain: DomainItem? { domains.first { $0.id == state.currentDomainID } }
    var activeSession: FocusSession? { sessions.last { $0.completedAt == nil } }
    var sessionStatus: SessionStatus {
        guard let session = activeSession else { return .waiting }
        return session.isRunning ? .started : .paused
    }
    var loadError: String?

    @ObservationIgnored private let store: DomainStore
    @ObservationIgnored private var storeLoaded = false
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let timeZone: TimeZone

    init(
        store: DomainStore = .applicationSupport,
        now: @escaping () -> Date = Date.init,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        self.store = store
        self.now = now
        self.timeZone = timeZone
        do {
            state = try store.loadState()
            storeLoaded = true
        } catch {
            loadError = "Your saved data hasn't been changed. Close and reopen the app to try again."
        }
    }

    // Start also resumes a paused session; the session's original day never changes.
    func startSession() throws {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        guard let currentDomain, sessionStatus != .started else { return }
        let date = now()
        var updated = state
        if let index = updated.sessions.lastIndex(where: { $0.completedAt == nil }) {
            updated.sessions[index].fragments.append(SessionFragment(startedAt: date))
        } else {
            updated.sessions.append(FocusSession(
                id: UUID().uuidString, domainID: currentDomain.id, domainName: currentDomain.name,
                day: DomainDay.key(for: date, in: timeZone),
                fragments: [SessionFragment(startedAt: date)]
            ))
        }
        try persist(updated)
    }

    func pauseSession() throws {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        guard sessionStatus == .started,
              let index = state.sessions.lastIndex(where: { $0.completedAt == nil }) else { return }
        var updated = state
        updated.sessions[index].pause(at: now())
        try persist(updated)
    }

    @discardableResult
    func stopSession() throws -> SessionSummary? {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        guard let domain = currentDomain, activeSession != nil else { return nil }
        let date = now()
        var updated = state
        let session = completeSession(in: &updated, at: date)!
        updated.currentDomainID = successor(of: domain.id, excluding: [])
        let summary = SessionSummary(
            id: session.id, domainName: domain.name, day: session.day,
            totalSeconds: updated.sessions.filter { $0.domainID == domain.id && $0.day == session.day }
                .reduce(0) { $0 + $1.elapsed(at: date) }
        )
        try persist(updated)
        return summary
    }

    func domainName(for session: FocusSession) -> String {
        domains.first { $0.id == session.domainID }?.name ?? session.domainName
    }

    func updateSessionDuration(id: String, duration: TimeInterval) throws {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        guard duration.isFinite, duration >= 0 else { throw DomainValidationError.invalidDuration }
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            throw DomainValidationError.missingSession
        }
        var updated = state
        // Keep the original fragments and attribution; a running session keeps
        // accumulating from this corrected total at the instant Save is pressed.
        updated.sessions[index].setDuration(duration, at: now())
        try persist(updated)
    }

    func deleteSessions(ids: Set<String>) throws {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        var updated = state
        updated.sessions.removeAll { ids.contains($0.id) }
        guard updated.sessions != sessions else { return }
        // Removing the unfinished record derives waiting status. Keep the cursor;
        // deleting tracked time is not completing a domain.
        try persist(updated)
    }

    func addDomain(named name: String) throws {
        let domain = DomainItem(name: try validatedName(name))
        var updated = state
        updated.domains.append(domain)
        if updated.currentDomainID == nil { updated.currentDomainID = domain.id }
        try persist(updated)
    }

    func setCurrentDomain(id: String) throws {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        guard activeSession == nil else { throw DomainValidationError.sessionInProgress }
        guard domains.contains(where: { $0.id == id }) else { throw DomainValidationError.missingDomain }
        guard state.currentDomainID != id else { return }
        var updated = state
        updated.currentDomainID = id
        try persist(updated)
    }

    func renameDomain(id: String, named name: String) throws {
        let trimmed = try validatedName(name)
        guard let index = domains.firstIndex(where: { $0.id == id }) else {
            throw DomainValidationError.missingDomain
        }
        var updated = state
        updated.domains[index].name = trimmed
        try persist(updated)
    }

    func deleteDomains(ids: Set<String>) throws {
        var updated = state
        updated.domains.removeAll { ids.contains($0.id) }
        guard updated.domains != domains else { return }
        if let currentID = state.currentDomainID, ids.contains(currentID) {
            _ = completeSession(in: &updated, at: now())
            updated.currentDomainID = successor(of: currentID, excluding: ids)
        }
        try persist(updated)
    }

    func reorderDomains(_ orderedIDs: [String]) throws {
        guard orderedIDs.count == domains.count, Set(orderedIDs) == Set(domains.map(\.id)) else {
            throw DomainValidationError.invalidOrder
        }
        guard orderedIDs != domains.map(\.id) else { return }
        var updated = state
        let byID = Dictionary(uniqueKeysWithValues: domains.map { ($0.id, $0) })
        updated.domains = orderedIDs.compactMap { byID[$0] }
        try persist(updated)
    }

    private func successor(of id: String, excluding deleted: Set<String>) -> String? {
        guard let index = domains.firstIndex(where: { $0.id == id }) else { return nil }
        for offset in 1...domains.count {
            let candidate = domains[(index + offset) % domains.count].id
            if !deleted.contains(candidate) { return candidate }
        }
        return nil
    }

    private func completeSession(in updated: inout DomainState, at date: Date) -> FocusSession? {
        guard let index = updated.sessions.lastIndex(where: { $0.completedAt == nil }) else { return nil }
        updated.sessions[index].pause(at: date)
        updated.sessions[index].completedAt = date
        return updated.sessions[index]
    }

    private func validatedName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DomainValidationError.emptyName }
        return trimmed
    }

    private func persist(_ updated: DomainState) throws {
        guard storeLoaded else { throw DomainValidationError.storeUnavailable }
        try store.saveState(updated)
        state = updated
    }

    @ObservationIgnored
    lazy var meadow = MeadowScene()
}
