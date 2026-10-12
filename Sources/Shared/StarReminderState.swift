import Foundation

/// Local usage summary only: no document names, contents or GitHub identity.
struct StarReminderState: Codable {
    enum StopReason: String, Codable { case supportLinkOpened, selfReportedStarred, optedOut }
    var firstSeen: Date
    var activeDays = 0
    var lastReadingDate: Date?
    var lastDisplay: Date?
    var displayCount = 0
    var cooldownUntil: Date?
    var stopReason: StopReason?

    mutating func recordReading(at now: Date, calendar: Calendar = .current) {
        let date = calendar.startOfDay(for: now)
        guard lastReadingDate.map({ date > $0 }) ?? true else { return }
        lastReadingDate = date
        activeDays += 1
    }

    func isEligible(at now: Date, calendar: Calendar = .current) -> Bool {
        guard stopReason == nil, activeDays >= 3, now.timeIntervalSince(firstSeen) >= 7 * 86400,
              cooldownUntil.map({ now >= $0 }) ?? true else { return false }
        if let lastDisplay {
            let interval: TimeInterval = displayCount == 1 ? 14 * 86400 : 30 * 86400
            guard now.timeIntervalSince(lastDisplay) >= interval,
                  let lastReadingDate, lastReadingDate > calendar.startOfDay(for: lastDisplay) else { return false }
        }
        return true
    }

    mutating func recordDisplay(at now: Date) {
        lastDisplay = now
        displayCount += 1
    }

    mutating func reenable(at now: Date) {
        stopReason = nil
        displayCount = 0
        lastDisplay = nil
        cooldownUntil = now.addingTimeInterval(14 * 86400)
    }
}
