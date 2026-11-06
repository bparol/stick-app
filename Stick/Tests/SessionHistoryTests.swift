import Foundation
import Testing
@testable import Stick

@MainActor
struct SessionHistoryTests {
    @Test func historyGroupsByOriginalDayAndSortsDaysAndSessionsNewestFirst() throws {
        let f = try HistoryFixture("2026-11-03T23:59:00Z")
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "Photo")
        try model.startSession()
        f.advance(120) // This session finishes after midnight but belongs to Nov 3.
        try model.stopSession()
        let oldest = try #require(model.sessions.first?.id)
        try model.startSession()
        f.advance(60)
        try model.stopSession()
        let middle = try #require(model.sessions.last?.id)
        f.advance(60)
        try model.startSession()
        try model.pauseSession()
        let newest = try #require(model.sessions.last?.id)
        f.advance(86_400)
        let restored = f.model()
        #expect(restored.sessionDays.map(\.day) == ["2026-11-04", "2026-11-03"])
        #expect(restored.sessionDays[0].sessions.map(\.id) == [newest, middle])
        #expect(restored.sessionDays[1].sessions.map(\.id) == [oldest])
        #expect(restored.sessionDays[0].sessions[0].completedAt == nil)
    }

    @Test func deletingCompletedSessionPersistsAndRemovesItFromFutureTotals() throws {
        let f = try HistoryFixture()
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "Photo")
        for seconds in [60.0, 120.0] {
            try model.startSession()
            f.advance(seconds)
            try model.stopSession()
        }
        let deletedID = try #require(model.sessions.first?.id)
        let keptID = try #require(model.sessions.last?.id)
        let current = model.currentDomain
        try model.deleteSessions(ids: [deletedID])
        #expect(model.currentDomain == current)
        #expect(f.model().sessions.map(\.id) == [keptID])
        try model.startSession()
        f.advance(30)
        #expect(try model.stopSession()?.totalSeconds == 150)
        try model.deleteSessions(ids: Set(model.sessions.map(\.id)))
        #expect(model.sessionDays.isEmpty)
        #expect(f.model().sessionDays.isEmpty)
        #expect(model.currentDomain == current)
    }

    @Test func deletingRunningOrPausedSessionResetsSameDomainWithoutAdvancing() throws {
        for paused in [false, true] {
            let f = try HistoryFixture()
            defer { f.clean() }
            let model = f.model()
            try model.addDomain(named: "Photo")
            try model.addDomain(named: "Reading")
            try model.startSession()
            f.advance(60)
            try model.stopSession()
            let completedID = try #require(model.sessions.first?.id)
            let current = model.currentDomain
            try model.startSession()
            f.advance(120)
            if paused { try model.pauseSession() }
            let activeID = try #require(model.activeSession?.id)
            try model.deleteSessions(ids: [activeID])
            #expect(model.sessionStatus == .waiting)
            #expect(model.activeSession == nil)
            #expect(model.currentDomain == current)
            let restored = f.model()
            #expect(restored.currentDomain == current)
            #expect(restored.sessionStatus == .waiting)
            #expect(restored.sessions.map(\.id) == [completedID])
            try restored.startSession()
            f.advance(10)
            #expect(try restored.stopSession()?.totalSeconds == 10)
        }
    }

    @Test func deletingOtherSessionDoesNotInterruptCurrentOne() throws {
        let f = try HistoryFixture()
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "Photo")
        try model.startSession()
        f.advance(60)
        try model.stopSession()
        let oldID = try #require(model.sessions.first?.id)
        try model.startSession()
        f.advance(30)
        let active = model.activeSession
        try model.deleteSessions(ids: [oldID, "already-deleted-id"])
        #expect(model.activeSession == active)
        #expect(model.sessionStatus == .started)
        #expect(f.model().activeSession == active)
        #expect(try model.stopSession()?.totalSeconds == 30)
    }

    @Test func failedSessionDeletionKeepsHistoryStatusAndCursor() throws {
        for status in ["completed", "started", "paused"] {
            let f = try HistoryFixture()
            defer { f.clean() }
            let model = f.model()
            try model.addDomain(named: "Photo")
            try model.addDomain(named: "Reading")
            try model.startSession()
            f.advance(60)
            if status == "completed" { try model.stopSession() }
            if status == "paused" { try model.pauseSession() }
            let original = model.sessions
            let cursor = model.currentDomain
            let originalStatus = model.sessionStatus
            try FileManager.default.removeItem(at: f.store.fileURL)
            try FileManager.default.createDirectory(at: f.store.fileURL, withIntermediateDirectories: true)
            #expect(throws: (any Error).self) { try model.deleteSessions(ids: Set(original.map(\.id))) }
            #expect(model.sessions == original)
            #expect(model.currentDomain == cursor)
            #expect(model.sessionStatus == originalStatus)
        }
    }

    @Test func namesRemainReadableAfterDomainRenameAndDeletion() throws {
        let f = try HistoryFixture()
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "Photography")
        let domainID = try #require(model.currentDomain?.id)
        try model.startSession()
        f.advance(60)
        try model.stopSession()
        let session = try #require(model.sessions.first)
        #expect(session.domainName == "Photography")
        try model.renameDomain(id: domainID, named: "Camera")
        #expect(model.domainName(for: session) == "Camera")
        try model.deleteDomains(ids: [domainID])
        let restored = f.model()
        let saved = try #require(restored.sessions.first)
        #expect(saved.domainName == "Photography")
        #expect(restored.domainName(for: saved) == "Photography")
        try restored.deleteSessions(ids: [saved.id])
        #expect(restored.sessionDays.isEmpty)
    }

    @Test func emptyHistoryAndUnknownDeletionDoNotCreateASnapshot() throws {
        let f = try HistoryFixture()
        defer { f.clean() }
        let model = f.model()
        #expect(model.sessionDays.isEmpty)
        try model.deleteSessions(ids: ["unknown"])
        #expect(!FileManager.default.fileExists(atPath: f.store.fileURL.path))
    }
}

@MainActor
private final class HistoryFixture {
    let folder = FileManager.default.temporaryDirectory.appending(path: "HistoryTests-\(UUID().uuidString)")
    var now: Date
    var store: DomainStore { DomainStore(fileURL: folder.appending(path: "sessions.json")) }
    init(_ date: String = "2026-11-03T12:00:00Z") throws {
        now = try #require(ISO8601DateFormatter().date(from: date))
    }
    func model() -> AppModel { AppModel(store: store, now: { self.now }, timeZone: TimeZone(secondsFromGMT: 0)!) }
    func advance(_ seconds: Double) { now.addTimeInterval(seconds) }
    func clean() { try? FileManager.default.removeItem(at: folder) }
}
