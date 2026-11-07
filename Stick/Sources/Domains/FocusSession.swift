import Foundation

struct SessionFragment: Codable, Equatable, Sendable {
    let startedAt: Date
    var endedAt: Date?
}

struct FocusSession: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let domainID: String
    let domainName: String
    let day: String
    var fragments: [SessionFragment]
    var completedAt: Date?
    var durationAdjustment: TimeInterval? = nil

    var startedAt: Date { fragments[0].startedAt }
    var isRunning: Bool { completedAt == nil && fragments.last?.endedAt == nil }

    func elapsed(at date: Date) -> TimeInterval {
        max(0, fragmentElapsed(at: date) + (durationAdjustment ?? 0))
    }

    mutating func setDuration(_ duration: TimeInterval, at date: Date) {
        durationAdjustment = duration - fragmentElapsed(at: date)
    }

    private func fragmentElapsed(at date: Date) -> TimeInterval {
        fragments.reduce(0) { total, fragment in
            total + max(0, (fragment.endedAt ?? date).timeIntervalSince(fragment.startedAt))
        }
    }

    mutating func pause(at date: Date) {
        guard isRunning else { return }
        fragments[fragments.count - 1].endedAt = date
    }
}

struct SessionDayGroup: Identifiable {
    let day: String
    let sessions: [FocusSession]
    var id: String { day }
}

enum SessionStatus: String {
    case waiting, started, paused
}

struct SessionSummary: Equatable, Identifiable {
    let id: String
    let domainName: String
    let day: String
    let totalSeconds: TimeInterval
}

enum SessionTime {
    static func hoursMinutes(_ seconds: TimeInterval) -> String {
        let minutes = Int(max(0, seconds) / 60)
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

enum DomainDay {
    static func key(for date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return String(
            format: "%04d-%02d-%02d",
            calendar.component(.year, from: date),
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }
}
