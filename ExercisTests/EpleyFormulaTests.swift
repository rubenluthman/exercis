import XCTest
@testable import Exercis

final class EpleyFormulaTests: XCTestCase {

    func testZeroRepsReturnsZero() {
        XCTAssertEqual(epleyE1RM(weight: 100, reps: 0), 0)
    }

    func testZeroWeightReturnsZero() {
        XCTAssertEqual(epleyE1RM(weight: 0, reps: 10), 0)
    }

    func testOneRep() {
        XCTAssertEqual(epleyE1RM(weight: 100, reps: 1), 100 * (1 + 1.0 / 30), accuracy: 0.001)
    }

    func testTenReps() {
        XCTAssertEqual(epleyE1RM(weight: 100, reps: 10), 100 * (1 + 10.0 / 30), accuracy: 0.001)
    }

    func testThirtyRepsDoublesWeight() {
        XCTAssertEqual(epleyE1RM(weight: 100, reps: 30), 200, accuracy: 0.001)
    }

    func testScalesLinearly() {
        let half = epleyE1RM(weight: 50, reps: 10)
        let full = epleyE1RM(weight: 100, reps: 10)
        XCTAssertEqual(full, half * 2, accuracy: 0.001)
    }
}
