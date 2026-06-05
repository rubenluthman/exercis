import XCTest
@testable import Exercis

final class ProgressionSuggestionTests: XCTestCase {

    func testNoIncreaseSuggestionKeepsWeight() {
        let s = progressionSuggestion(prevMax: 100, shouldIncrease: false, bestSetReps: 5)
        XCTAssertEqual(s.weight, 100, accuracy: 0.001)
        XCTAssertEqual(s.reps, 5)
    }

    func testIncreaseSuggestionAdds2_5kg() {
        let s = progressionSuggestion(prevMax: 100, shouldIncrease: true, bestSetReps: 5)
        XCTAssertEqual(s.weight, 102.5, accuracy: 0.001)
        XCTAssertEqual(s.reps, 5)
    }

    func testRepsPreserved() {
        let s = progressionSuggestion(prevMax: 80, shouldIncrease: false, bestSetReps: 8)
        XCTAssertEqual(s.reps, 8)
    }

    func testZeroRepsPreserved() {
        let s = progressionSuggestion(prevMax: 100, shouldIncrease: true, bestSetReps: 0)
        XCTAssertEqual(s.reps, 0)
    }

    func testIncrementIsExactly2_5() {
        let withIncrease    = progressionSuggestion(prevMax: 60, shouldIncrease: true,  bestSetReps: 3)
        let withoutIncrease = progressionSuggestion(prevMax: 60, shouldIncrease: false, bestSetReps: 3)
        XCTAssertEqual(withIncrease.weight - withoutIncrease.weight, 2.5, accuracy: 0.001)
    }
}
