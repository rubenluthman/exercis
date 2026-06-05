import XCTest
@testable import Exercis

@MainActor
final class HistoryGroupingTests: XCTestCase {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return Calendar.current.date(from: comps)!
    }

    private func workout(on date: Date) -> HistoryEntry {
        let s = WorkoutSession(date: date)
        return .workout(s)
    }

    private func cardio(on date: Date) -> HistoryEntry {
        let s = CardioSession(date: date, durationMinutes: 30, cardioType: "running")
        return .cardio(s)
    }

    // MARK: groupHistoryEntries

    func testEntriesGroupedByMonth() {
        let entries = [
            workout(on: date(2025, 1, 10)),
            workout(on: date(2025, 1, 20)),
            cardio(on:  date(2025, 2, 5)),
        ]
        let groups = groupHistoryEntries(entries)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].year, 2025); XCTAssertEqual(groups[0].month, 2)
        XCTAssertEqual(groups[1].year, 2025); XCTAssertEqual(groups[1].month, 1)
    }

    func testGroupsSortedNewestFirst() {
        let entries = [
            workout(on: date(2024, 6, 1)),
            workout(on: date(2025, 3, 1)),
            workout(on: date(2024, 12, 1)),
        ]
        let groups = groupHistoryEntries(entries)
        let months = groups.map { ($0.year, $0.month) }
        XCTAssertEqual(months[0].0, 2025); XCTAssertEqual(months[0].1, 3)
        XCTAssertEqual(months[1].0, 2024); XCTAssertEqual(months[1].1, 12)
        XCTAssertEqual(months[2].0, 2024); XCTAssertEqual(months[2].1, 6)
    }

    func testEntriesWithinGroupSortedNewestFirst() {
        let early = date(2025, 1, 5)
        let late  = date(2025, 1, 25)
        let entries = [workout(on: early), workout(on: late)]
        let group = groupHistoryEntries(entries)[0]
        XCTAssertEqual(group.entries[0].date, late)
        XCTAssertEqual(group.entries[1].date, early)
    }

    func testWorkoutAndCardioCountsInGroup() {
        let entries = [
            workout(on: date(2025, 1, 1)),
            workout(on: date(2025, 1, 2)),
            cardio(on:  date(2025, 1, 3)),
        ]
        let group = groupHistoryEntries(entries)[0]
        XCTAssertEqual(group.workoutCount, 2)
        XCTAssertEqual(group.cardioCount, 1)
    }

    func testEmptyInputReturnsNoGroups() {
        XCTAssertTrue(groupHistoryEntries([]).isEmpty)
    }

    // MARK: buildHistoryRows

    func testSingleYearHasNoYearRow() {
        let entries = [
            workout(on: date(2025, 1, 1)),
            workout(on: date(2025, 3, 1)),
        ]
        let rows = buildHistoryRows(groupHistoryEntries(entries))
        let yearRows = rows.filter { if case .year = $0 { return true }; return false }
        XCTAssertTrue(yearRows.isEmpty, "Should not show year header when all data is in same year")
    }

    func testMultipleYearsShowYearRows() {
        let entries = [
            workout(on: date(2024, 12, 1)),
            workout(on: date(2025, 1, 1)),
        ]
        let rows = buildHistoryRows(groupHistoryEntries(entries))
        let yearRows = rows.filter { if case .year = $0 { return true }; return false }
        XCTAssertEqual(yearRows.count, 2)
    }

    func testYearRowAppearsBeforeFirstMonthOfThatYear() {
        let entries = [
            workout(on: date(2024, 6, 1)),
            workout(on: date(2025, 1, 1)),
        ]
        let rows = buildHistoryRows(groupHistoryEntries(entries))
        // First row should be year 2025, then month 2025-01, then year 2024, then month 2024-06
        XCTAssertEqual(rows.count, 4)
        if case .year(let y) = rows[0] { XCTAssertEqual(y, 2025) } else { XCTFail("Expected year row first") }
        if case .month(let g) = rows[1] { XCTAssertEqual(g.year, 2025) } else { XCTFail("Expected month row") }
    }
}
