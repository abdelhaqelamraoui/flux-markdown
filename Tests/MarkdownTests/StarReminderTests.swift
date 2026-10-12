import XCTest

final class StarReminderTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    func day(_ n: Double) -> Date { start.addingTimeInterval(n * 86400) }
    func eligible() -> StarReminderState {
        var state = StarReminderState(firstSeen: start)
        for n in [0.0, 1, 7] { state.recordReading(at: day(n)) }
        return state
    }
    func testFirstInvitationNeedsBothAgeAndThreeDates() {
        var state = StarReminderState(firstSeen: start)
        state.recordReading(at: day(0)); state.recordReading(at: day(7))
        XCTAssertFalse(state.isEligible(at: day(7)))
        state.recordReading(at: day(8))
        XCTAssertTrue(state.isEligible(at: day(8)))
        XCTAssertFalse(eligible().isEligible(at: day(7).addingTimeInterval(-1)))
    }
    func testSameDateAndClockRollbackDoNotAddDays() {
        var state = eligible()
        state.recordReading(at: day(7)); state.recordReading(at: day(1))
        XCTAssertEqual(state.activeDays, 3)
        XCTAssertFalse(state.isEligible(at: day(-1)))
    }
    func testFourteenThenThirtyDaysContinueWithoutCap() {
        var state = eligible()
        state.recordDisplay(at: day(7))
        for n in 1...8 {
            let due = 21.0 + Double(n - 1) * 30
            state.recordReading(at: day(due))
            XCTAssertFalse(state.isEligible(at: day(due).addingTimeInterval(-1)))
            XCTAssertTrue(state.isEligible(at: day(due)))
            state.recordDisplay(at: day(due))
            XCTAssertFalse(state.isEligible(at: day(due)))
        }
        XCTAssertEqual(state.displayCount, 9)
    }
    func testRequiresNewReadingDateAndDoesNotReplayMissedInvitations() {
        var state = eligible(); state.recordDisplay(at: day(7))
        XCTAssertFalse(state.isEligible(at: day(200)))
        state.recordReading(at: day(200))
        XCTAssertTrue(state.isEligible(at: day(200)))
        state.recordDisplay(at: day(200))
        state.recordReading(at: day(201))
        XCTAssertFalse(state.isEligible(at: day(201)))
    }
    func testStopReasonsAndExplicitReenable() {
        for reason in [StarReminderState.StopReason.supportLinkOpened, .selfReportedStarred, .optedOut] {
            var state = eligible(); state.stopReason = reason
            XCTAssertFalse(state.isEligible(at: day(100)))
            state.reenable(at: day(100))
            state.recordReading(at: day(114))
            XCTAssertFalse(state.isEligible(at: day(114).addingTimeInterval(-1)))
            XCTAssertTrue(state.isEligible(at: day(114)))
        }
    }
    func testStateRoundTripKeepsCooldownAndStopReason() throws {
        var state = eligible(); state.recordDisplay(at: day(7)); state.stopReason = .optedOut
        let copy = try JSONDecoder().decode(StarReminderState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(copy.displayCount, 1)
        XCTAssertEqual(copy.stopReason, .optedOut)
        XCTAssertEqual(copy.lastDisplay, day(7))
    }
}

final class StarReminderStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private let now = Date(timeIntervalSince1970: 1_700_700_000)
    override func setUp() {
        suite = "FluxMarkdown.StarReminderTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() { defaults.removePersistentDomain(forName: suite) }
    private func store() throws -> StarReminderStore {
        var state = StarReminderState(firstSeen: now.addingTimeInterval(-8 * 86400))
        for days in [-8.0, -7, 0] { state.recordReading(at: now.addingTimeInterval(days * 86400)) }
        defaults.set(try JSONEncoder().encode(state), forKey: StarReminderStore.key)
        return StarReminderStore(defaults: defaults, now: now)
    }
    func testMultipleWindowsClaimOnlyOneDisplayAndDismissKeepsCooldown() throws {
        let store = try store(), first = UUID(), second = UUID()
        XCTAssertTrue(store.claim(first, now: now))
        XCTAssertFalse(store.claim(second, now: now))
        store.dismiss(second)
        XCTAssertEqual(store.owner, first)
        store.dismiss(first)
        XCTAssertNil(store.owner)
        XCTAssertFalse(store.claim(second, now: now))
        let restored = StarReminderStore(defaults: defaults, now: now)
        XCTAssertEqual(restored.state.displayCount, 1)
    }
    func testSuccessfulBrowserHandoffStopsAndFailureDoesNot() throws {
        let store = try store()
        XCTAssertTrue(store.claim(UUID(), now: now))
        XCTAssertFalse(GitHubStar.openRepository { _ in false })
        XCTAssertNotNil(store.owner)
        XCTAssertTrue(store.enabled)
        XCTAssertTrue(GitHubStar.openRepository { _ in true })
        XCTAssertNil(store.owner)
        XCTAssertEqual(store.state.stopReason, .supportLinkOpened)
    }
    func testSettingsDisableDismissesAndReenablePreservesUsage() throws {
        let store = try store()
        XCTAssertTrue(store.claim(UUID(), now: now))
        store.setEnabled(false)
        XCTAssertNil(store.owner)
        XCTAssertFalse(store.enabled)
        store.setEnabled(true)
        XCTAssertTrue(store.enabled)
        XCTAssertEqual(store.state.activeDays, 3)
        XCTAssertNotNil(store.state.cooldownUntil)
        XCTAssertEqual(store.state.displayCount, 0)
    }
    func testThirtySecondsAggregateAndCountOnlyOncePerDate() {
        let store = StarReminderStore(defaults: defaults, now: now)
        store.recordReading(seconds: 29, now: now)
        XCTAssertEqual(store.state.activeDays, 0)
        store.recordReading(seconds: 1, now: now)
        store.recordReading(seconds: 60, now: now)
        XCTAssertEqual(store.state.activeDays, 1)
        store.recordReading(seconds: 29, now: now.addingTimeInterval(86400))
        XCTAssertEqual(store.state.activeDays, 1)
        store.recordReading(seconds: 1, now: now.addingTimeInterval(86400))
        XCTAssertEqual(store.state.activeDays, 2)
    }
}
