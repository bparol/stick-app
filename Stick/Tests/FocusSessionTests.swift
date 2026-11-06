import Foundation
import Testing
@testable import Stick

@MainActor
struct FocusSessionTests {
    @Test func fragmentsPersistAcrossShutdownAndExcludePausedTime() throws {
        let f = try Fixture()
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "Photography")
        #expect(model.sessionStatus == .waiting)
        try model.startSession()
        let start = f.now
        f.advance(90)
        let running = f.model()
        #expect(running.sessionStatus == .started)
        #expect(running.activeSession?.elapsed(at: f.now) == 90)
        try running.pauseSession()
        let pause = f.now
        f.advance(600)
        let paused = f.model()
        #expect(paused.sessionStatus == .paused)
        #expect(paused.activeSession?.elapsed(at: f.now) == 90)
        try paused.startSession()
        let resume = f.now
        f.advance(30)
        let summary = try #require(try paused.stopSession())
        #expect(summary.totalSeconds == 120)
        let saved = try #require(f.model().sessions.first)
        #expect(saved.startedAt == start)
        #expect(saved.fragments.map(\.startedAt) == [start, resume])
        #expect(saved.fragments.map(\.endedAt) == [pause, f.now])
        #expect(saved.completedAt == f.now)
        #expect(saved.elapsed(at: f.now.addingTimeInterval(500)) == 120)
        #expect(f.model().sessionStatus == .waiting)
    }

    @Test func midnightResumesKeepOriginalDayAndNewStartUsesNewDay() throws {
        let f = try Fixture("2026-11-03T23:59:00Z")
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "Photo")
        try model.addDomain(named: "Reading")
        let ids = model.domains.map(\.id)
        try model.startSession()
        f.advance(120)
        try model.pauseSession()
        f.advance(86_400)
        let restored = f.model()
        #expect(restored.currentDomain?.id == ids[0])
        try restored.startSession()
        f.advance(60)
        let summary = try #require(try restored.stopSession())
        #expect(summary.day == "2026-11-03")
        #expect(summary.totalSeconds == 180)
        #expect(restored.currentDomain?.id == ids[1])
        try restored.startSession()
        #expect(restored.activeSession?.day == "2026-11-05")
    }

    @Test func stopAdvancesCursorWithoutChangingOrderWrapsAndTotalsByTopicAndDay() throws {
        let f = try Fixture()
        defer { f.clean() }
        let model = f.model()
        for name in ["Photo", "Reading"] { try model.addDomain(named: name) }
        let original = model.domains
        for duration in [60.0, 120.0, 30.0] {
            try model.startSession()
            f.advance(duration)
            let summary = try #require(try model.stopSession())
            #expect(summary.totalSeconds == (duration == 30 ? 90 : duration))
        }
        #expect(model.domains == original)
        #expect(model.currentDomain == original[1])
        #expect(model.sessions.count == 3)
        #expect(f.model().currentDomain == original[1])
        f.advance(86_400 * 10)
        #expect(f.model().currentDomain == original[1])
        try model.startSession()
        f.advance(10)
        #expect(try model.stopSession()?.totalSeconds == 10)
    }

    @Test func reorderingAndRenamingPreserveCurrentSessionAndStopUsesLatestSuccessor() throws {
        let f = try Fixture()
        defer { f.clean() }
        let model = f.model()
        for name in ["A", "B", "C"] { try model.addDomain(named: name) }
        let ids = model.domains.map(\.id)
        try model.startSession()
        f.advance(90)
        try model.reorderDomains([ids[1], ids[0], ids[2]])
        try model.renameDomain(id: ids[0], named: "Camera")
        #expect(model.currentDomain?.name == "Camera")
        #expect(model.sessionStatus == .started)
        #expect(model.activeSession?.elapsed(at: f.now) == 90)
        #expect(f.model().currentDomain?.id == ids[0])
        #expect(try model.stopSession()?.domainName == "Camera")
        #expect(model.currentDomain?.id == ids[2])
        #expect(model.domains.map(\.id) == [ids[1], ids[0], ids[2]])
    }

    @Test func deletingCurrentCompletesRunningOrPausedSessionAndRetainsHistory() throws {
        for paused in [false, true] {
            let f = try Fixture()
            defer { f.clean() }
            let model = f.model()
            for name in ["A", "B", "C", "D"] { try model.addDomain(named: name) }
            let ids = model.domains.map(\.id)
            try model.startSession()
            f.advance(60)
            if paused { try model.pauseSession(); f.advance(120) }
            try model.deleteDomains(ids: [ids[0], ids[1]])
            #expect(model.currentDomain?.id == ids[2])
            #expect(model.sessionStatus == .waiting)
            #expect(model.sessions.first?.elapsed(at: f.now) == 60)
            #expect(model.sessions.first?.completedAt == f.now)
            #expect(model.sessions.first?.domainID == ids[0])
            try model.deleteDomains(ids: [ids[3]])
            #expect(model.currentDomain?.id == ids[2])
            try model.deleteDomains(ids: [ids[2]])
            #expect(model.currentDomain == nil)
            #expect(f.model().sessions.count == 1)
            try model.addDomain(named: "New")
            #expect(model.currentDomain?.name == "New")
        }
    }

    @Test func deletingWaitingCurrentWrapsToNextSurvivor() throws {
        let f = try Fixture()
        defer { f.clean() }
        let model = f.model()
        for name in ["A", "B", "C"] { try model.addDomain(named: name) }
        let ids = model.domains.map(\.id)
        try model.reorderDomains([ids[1], ids[2], ids[0]])
        try model.deleteDomains(ids: [ids[0]])
        #expect(model.currentDomain?.id == ids[1])
        #expect(model.sessions.isEmpty)
    }

    @Test func failedWritesDoNotPublishSessionCursorOrOrderingChanges() throws {
        for action in ["start", "pause", "resume", "stop", "delete", "reorder"] {
            let f = try Fixture()
            defer { f.clean() }
            let model = f.model()
            try model.addDomain(named: "A")
            try model.addDomain(named: "B")
            if action != "start" { try model.startSession(); f.advance(60) }
            if action == "resume" { try model.pauseSession() }
            let before = try f.store.loadState()
            try FileManager.default.removeItem(at: f.store.fileURL)
            try FileManager.default.createDirectory(at: f.store.fileURL, withIntermediateDirectories: true)
            #expect(throws: (any Error).self) {
                switch action {
                case "start", "resume": try model.startSession()
                case "pause": try model.pauseSession()
                case "stop": _ = try model.stopSession()
                case "delete": try model.deleteDomains(ids: [model.currentDomain!.id])
                default: try model.reorderDomains(model.domains.reversed().map(\.id))
                }
            }
            #expect(model.sessions == before.sessions)
            #expect(model.domains == before.domains)
            #expect(model.currentDomain?.id == before.currentDomainID)
        }
    }

    @Test func repeatedActionsCannotDuplicateFragmentsOrSkipTopics() throws {
        let f = try Fixture()
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "A")
        try model.addDomain(named: "B")
        #expect(try model.stopSession() == nil)
        try model.pauseSession()
        try model.startSession()
        try model.startSession()
        f.advance(10)
        try model.pauseSession()
        try model.pauseSession()
        #expect(model.activeSession?.fragments.count == 1)
        #expect(try model.stopSession()?.totalSeconds == 10)
        #expect(try model.stopSession() == nil)
        #expect(model.currentDomain?.name == "B")
    }

    @Test func invalidOrderAndEmptyNamesLeaveDataUnchanged() throws {
        let f = try Fixture()
        defer { f.clean() }
        let model = f.model()
        try model.addDomain(named: "A")
        try model.addDomain(named: "B")
        let original = try f.store.loadState()
        let id = model.domains[0].id
        #expect(throws: DomainValidationError.invalidOrder) { try model.reorderDomains([id, id]) }
        #expect(throws: DomainValidationError.invalidOrder) { try model.reorderDomains([id]) }
        #expect(throws: DomainValidationError.emptyName) { try model.renameDomain(id: id, named: " \n") }
        #expect(try f.store.loadState() == original)
    }

    @Test func localDayAndHourMinuteFormatting() throws {
        let zone = try #require(TimeZone(identifier: "Europe/Warsaw"))
        let now = try #require(ISO8601DateFormatter().date(from: "2026-11-03T23:30:00Z"))
        #expect(DomainDay.key(for: now, in: zone) == "2026-11-04")
        #expect(SessionTime.hoursMinutes(0) == "00:00")
        #expect(SessionTime.hoursMinutes(3_659) == "01:00")
        #expect(SessionTime.hoursMinutes(3_660) == "01:01")
        #expect(SessionTime.hoursMinutes(360_000) == "100:00")
    }
}

@MainActor
private final class Fixture {
    let folder = FileManager.default.temporaryDirectory.appending(path: "SessionTests-\(UUID().uuidString)")
    var now: Date
    var store: DomainStore { DomainStore(fileURL: folder.appending(path: "domains.json")) }
    init(_ date: String = "2026-11-03T12:00:00Z") throws {
        now = try #require(ISO8601DateFormatter().date(from: date))
    }
    func model() -> AppModel { AppModel(store: store, now: { self.now }, timeZone: TimeZone(secondsFromGMT: 0)!) }
    func advance(_ seconds: Double) { now.addTimeInterval(seconds) }
    func clean() { try? FileManager.default.removeItem(at: folder) }
}
