import Foundation

struct DomainStore {
    let fileURL: URL

    static var applicationSupport: Self {
        let folder = URL.applicationSupportDirectory.appending(path: "Stick", directoryHint: .isDirectory)
        #if DEBUG
        // UI tests use isolated files; they never reset the person's saved domains.
        if let token = ProcessInfo.processInfo.environment["DOMAIN_UI_TEST_STORE"],
           UUID(uuidString: token) != nil {
            return Self(fileURL: folder.appending(path: "UITests/\(token).json"))
        }
        #endif
        // Fresh session schema; previous development snapshots are not migrated.
        return Self(fileURL: folder.appending(path: "sessions.json"))
    }

    func loadState() throws -> DomainState {
        let data: Data
        do { data = try Data(contentsOf: fileURL) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return DomainState() }
        let state = try JSONDecoder().decode(DomainState.self, from: data)
        guard state.isValid else { throw CocoaError(.fileReadCorruptFile) }
        return state
    }

    func saveState(_ state: DomainState) throws {
        let data = try JSONEncoder().encode(state)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [DomainItem] { try loadState().domains }
}

struct DomainState: Codable, Equatable {
    var domains: [DomainItem] = []
    var currentDomainID: String?
    var sessions: [FocusSession] = []

    // Reject inconsistent snapshots rather than silently discarding tracked time.
    var isValid: Bool {
        let ids = Set(domains.map(\.id))
        guard ids.count == domains.count,
              Set(sessions.map(\.id)).count == sessions.count,
              domains.isEmpty ? currentDomainID == nil : currentDomainID.map(ids.contains) == true
        else { return false }
        let unfinished = sessions.filter { $0.completedAt == nil }
        guard unfinished.count <= 1,
              unfinished.allSatisfy({ $0.domainID == currentDomainID }) else { return false }
        return sessions.allSatisfy { session in
            !session.fragments.isEmpty && session.fragments.enumerated().allSatisfy { index, fragment in
                fragment.endedAt != nil || (index == session.fragments.count - 1 && session.completedAt == nil)
            }
        }
    }
}
