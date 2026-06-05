import XCTest
@testable import Exercis

final class PRDetectionTests: XCTestCase {

    // Mirrors computeNewPRs logic: is currentBest > historicalBest?
    private func isPR(current: [(weight: Double, reps: Int)], historical: [(weight: Double, reps: Int)]) -> Bool {
        let currentBest = current.map { epleyE1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        let historicalBest = historical.map { epleyE1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        return currentBest > historicalBest
    }

    func testHigherWeightSameRepsIsPR() {
        XCTAssertTrue(isPR(
            current:    [(100, 5)],
            historical: [(95, 5)]
        ))
    }

    func testLowerWeightIsNotPR() {
        XCTAssertFalse(isPR(
            current:    [(90, 5)],
            historical: [(95, 5)]
        ))
    }

    func testSameWeightAndRepsIsNotPR() {
        XCTAssertFalse(isPR(
            current:    [(100, 5)],
            historical: [(100, 5)]
        ))
    }

    func testHigherRepsLowerWeightMayBePR() {
        // 80 kg × 10 reps → e1RM ≈ 106.7
        // 100 kg × 1 rep  → e1RM ≈ 103.3
        XCTAssertTrue(isPR(
            current:    [(80, 10)],
            historical: [(100, 1)]
        ))
    }

    func testEmptyHistoryIsAlwaysPR() {
        XCTAssertTrue(isPR(
            current:    [(100, 5)],
            historical: []
        ))
    }

    func testZeroWeightIsNeverPR() {
        XCTAssertFalse(isPR(
            current:    [(0, 5)],
            historical: []
        ))
    }

    func testBestSetAcrossMultipleSetsIsUsed() {
        // Sets: 80×5, 85×5, 90×5 — best is 90×5
        XCTAssertTrue(isPR(
            current:    [(80, 5), (85, 5), (90, 5)],
            historical: [(88, 5)]
        ))
    }

    func testBestHistoricalSetAcrossSessionsIsUsed() {
        XCTAssertFalse(isPR(
            current:    [(90, 5)],
            historical: [(90, 5), (95, 5), (80, 8)]
        ))
    }

    func testOneRepMaxExactlyEqualIsNotPR() {
        let e1rm = epleyE1RM(weight: 100, reps: 5)
        // same e1RM from different weight/rep combo
        let altWeight = e1rm          // 1 rep at e1rm value
        XCTAssertFalse(isPR(
            current:    [(altWeight, 1)],
            historical: [(100, 5)]
        ))
    }
}
