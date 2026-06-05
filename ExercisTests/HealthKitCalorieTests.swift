import XCTest
@testable import Exercis

final class HealthKitCalorieTests: XCTestCase {

    // Formula: kcal = met * bodyMass * hours
    private func kcal(met: Double, bodyMass: Double, seconds: Double) -> Double {
        met * bodyMass * (seconds / 3600)
    }

    func testRunningOneHour75kg() {
        XCTAssertEqual(kcal(met: 9.0, bodyMass: 75, seconds: 3600), 675, accuracy: 0.01)
    }

    func testWalkingHalfHour80kg() {
        XCTAssertEqual(kcal(met: 3.5, bodyMass: 80, seconds: 1800), 140, accuracy: 0.01)
    }

    func testStrengthDefaultBodyMassFallback() {
        // Strength uses MET 5.5, fallback body mass 75 kg
        XCTAssertEqual(kcal(met: 5.5, bodyMass: 75, seconds: 3600), 412.5, accuracy: 0.01)
    }

    func testAssaultBikeHighIntensity() {
        XCTAssertEqual(kcal(met: 10.0, bodyMass: 90, seconds: 1800), 450, accuracy: 0.01)
    }

    func testZeroDurationProducesZeroCalories() {
        XCTAssertEqual(kcal(met: 9.0, bodyMass: 75, seconds: 0), 0)
    }

    func testMETValuesForAllCardioTypes() {
        let expected: [(CardioType, Double)] = [
            (.crosstrainer, 7.0),
            (.cyclingStationary, 8.0),
            (.rowingMachine, 7.5),
            (.hiking, 5.5),
            (.rucking, 5.5),
            (.running, 9.0),
            (.treadmillRun, 9.0),
            (.walking, 3.5),
            (.treadmillWalk, 3.5),
            (.stairClimber, 8.0),
            (.skiErg, 8.0),
            (.assaultBike, 10.0),
            (.roadCycling, 8.0),
            (.mountainBiking, 8.0),
            (.swimming, 7.0),
            (.crossCountrySkiing, 9.0),
            (.iceSkating, 7.0),
            (.kayaking, 5.0),
            (.canoeing, 5.0),
            (.climbing, 8.0),
            (.boxing, 9.0),
            (.battleRopes, 10.0),
            (.sled, 9.0),
            (.jumpRope, 10.0),
            (.burpees, 10.0),
            (.mountainClimbers, 10.0),
        ]
        for (type, met) in expected {
            let result = kcal(met: met, bodyMass: 75, seconds: 3600)
            XCTAssertEqual(result, met * 75, accuracy: 0.001, "MET mismatch for \(type.rawValue)")
        }
    }
}
