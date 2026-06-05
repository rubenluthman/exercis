import XCTest
@testable import Exercis

final class ReminderManagerTests: XCTestCase {

    private func session(startHour: Int, startMinute: Int, daysAgo: Int = 0) -> WorkoutSession {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.day! -= daysAgo
        comps.hour = startHour
        comps.minute = startMinute
        let s = WorkoutSession()
        s.startDate = Calendar.current.date(from: comps)!
        return s
    }

    func testReturnsTimeFromLatestSession() {
        let sessions = [
            session(startHour: 18, startMinute: 30, daysAgo: 1),
            session(startHour: 7,  startMinute: 0,  daysAgo: 5),
        ]
        let (h, m) = ReminderManager.suggestedTime(from: sessions)
        XCTAssertEqual(h, 18)
        XCTAssertEqual(m, 30)
    }

    func testEmptySessionsFallsBackTo17() {
        let (h, m) = ReminderManager.suggestedTime(from: [])
        XCTAssertEqual(h, 17)
        XCTAssertEqual(m, 0)
    }

    func testSingleSession() {
        let sessions = [session(startHour: 6, startMinute: 45)]
        let (h, m) = ReminderManager.suggestedTime(from: sessions)
        XCTAssertEqual(h, 6)
        XCTAssertEqual(m, 45)
    }

    func testPicksMostRecentNotFirst() {
        let sessions = [
            session(startHour: 9,  startMinute: 0,  daysAgo: 10),
            session(startHour: 20, startMinute: 15, daysAgo: 0),
        ]
        let (h, m) = ReminderManager.suggestedTime(from: sessions)
        XCTAssertEqual(h, 20)
        XCTAssertEqual(m, 15)
    }
}
