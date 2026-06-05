import XCTest
@testable import Exercis

final class StreakTests: XCTestCase {

    private func day(_ daysAgo: Int) -> Date {
        let cal = Calendar.current
        return cal.startOfDay(for: cal.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    // MARK: - computeCurrentStreak

    func testEmptyDaysReturnsZero() {
        XCTAssertEqual(computeCurrentStreak(days: []), 0)
    }

    func testTodayAloneIsStreakOne() {
        XCTAssertEqual(computeCurrentStreak(days: [day(0)]), 1)
    }

    func testYesterdayAloneIsStreakOne() {
        XCTAssertEqual(computeCurrentStreak(days: [day(1)]), 1)
    }

    func testTwoDaysAgoAloneIsStreakZero() {
        XCTAssertEqual(computeCurrentStreak(days: [day(2)]), 0)
    }

    func testConsecutiveDaysIncludingToday() {
        XCTAssertEqual(computeCurrentStreak(days: [day(0), day(1), day(2)]), 3)
    }

    func testConsecutiveDaysEndingYesterday() {
        XCTAssertEqual(computeCurrentStreak(days: [day(1), day(2), day(3)]), 3)
    }

    func testGapBreaksStreak() {
        XCTAssertEqual(computeCurrentStreak(days: [day(0), day(2)]), 1)
    }

    func testLongStreakWithGapInMiddle() {
        let days: Set<Date> = [day(0), day(1), day(2), day(4), day(5)]
        XCTAssertEqual(computeCurrentStreak(days: days), 3)
    }

    // MARK: - computeBestStreak

    func testBestStreakEmptyIsZero() {
        XCTAssertEqual(computeBestStreak(days: []), 0)
    }

    func testBestStreakSingleDay() {
        XCTAssertEqual(computeBestStreak(days: [day(5)]), 1)
    }

    func testBestStreakConsecutive() {
        XCTAssertEqual(computeBestStreak(days: [day(0), day(1), day(2)]), 3)
    }

    func testBestStreakPicksLongestRun() {
        let days: Set<Date> = [day(0), day(1), day(3), day(4), day(5), day(6)]
        XCTAssertEqual(computeBestStreak(days: days), 4)
    }

    func testBestStreakWithMultipleEqualRuns() {
        let days: Set<Date> = [day(0), day(1), day(3), day(4)]
        XCTAssertEqual(computeBestStreak(days: days), 2)
    }
}
