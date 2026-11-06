import Foundation
import Testing
@testable import Stick

@MainActor
struct CurrentDomainTests {
    @Test func selectingWaitingDomainPersistsCursorWithoutReorderingOrChangingHistory() throws {
        let f = SelectionFixture()
        defer { f.clean() }
        let model = AppModel(store: f.store)
        for name in ["Photo", "Reading", "Guitar"] { try model.addDomain(named: name) }
        try model.startSession()
        try model.stopSession()
        let order = model.domains
        let history = model.sessions
        try model.setCurrentDomain(id: order[2].id)
        #expect(model.currentDomain == order[2])
        #expect(model.sessionStatus == .waiting)
        #expect(model.domains == order)
        #expect(model.sessions == history)
        let restored = AppModel(store: f.store)
        #expect(restored.currentDomain == order[2])
        #expect(restored.domains == order)
        #expect(restored.sessions == history)
        try restored.startSession()
        try restored.stopSession()
        #expect(restored.currentDomain == order[0]) // Continue from the selected row's place.
    }

    @Test func runningAndPausedSessionsCannotChangeCurrentDomain() throws {
        for paused in [false, true] {
            let f = SelectionFixture()
            defer { f.clean() }
            let model = AppModel(store: f.store)
            try model.addDomain(named: "Photo")
            try model.addDomain(named: "Reading")
            try model.startSession()
            if paused { try model.pauseSession() }
            let original = try f.store.loadState()
            #expect(throws: DomainValidationError.sessionInProgress) {
                try model.setCurrentDomain(id: model.domains[1].id)
            }
            #expect(model.currentDomain?.id == original.currentDomainID)
            #expect(model.sessions == original.sessions)
            #expect(try f.store.loadState() == original)
        }
    }

    @Test func failedSelectionSaveKeepsCurrentDomainAndSnapshot() throws {
        let f = SelectionFixture()
        defer { f.clean() }
        let model = AppModel(store: f.store)
        try model.addDomain(named: "Photo")
        try model.addDomain(named: "Reading")
        let original = try f.store.loadState()
        try FileManager.default.removeItem(at: f.store.fileURL)
        try FileManager.default.createDirectory(at: f.store.fileURL, withIntermediateDirectories: true)
        #expect(throws: (any Error).self) { try model.setCurrentDomain(id: model.domains[1].id) }
        #expect(model.currentDomain?.id == original.currentDomainID)
        #expect(model.domains == original.domains)
        #expect(model.sessions == original.sessions)
        #expect(model.sessionStatus == .waiting)
    }

    @Test func missingDomainIsRejectedAndSelectingCurrentDomainDoesNotWrite() throws {
        let f = SelectionFixture()
        defer { f.clean() }
        let model = AppModel(store: f.store)
        try model.addDomain(named: "Photo")
        let original = try f.store.loadState()
        #expect(throws: DomainValidationError.missingDomain) { try model.setCurrentDomain(id: "deleted-id") }
        #expect(try f.store.loadState() == original)
        try FileManager.default.removeItem(at: f.store.fileURL)
        try FileManager.default.createDirectory(at: f.store.fileURL, withIntermediateDirectories: true)
        try model.setCurrentDomain(id: model.domains[0].id)
        #expect(model.currentDomain?.id == original.currentDomainID)
    }

    @Test func unreadableStoreCannotBeOverwrittenBySelection() throws {
        let f = SelectionFixture()
        defer { f.clean() }
        try FileManager.default.createDirectory(at: f.folder, withIntermediateDirectories: true)
        let original = Data("unreadable snapshot".utf8)
        try original.write(to: f.store.fileURL)
        let model = AppModel(store: f.store)
        #expect(throws: DomainValidationError.storeUnavailable) { try model.setCurrentDomain(id: "any-id") }
        #expect(try Data(contentsOf: f.store.fileURL) == original)
    }
}

private struct SelectionFixture {
    let folder = FileManager.default.temporaryDirectory.appending(path: "SelectionTests-\(UUID().uuidString)")
    var store: DomainStore { DomainStore(fileURL: folder.appending(path: "sessions.json")) }
    func clean() { try? FileManager.default.removeItem(at: folder) }
}
