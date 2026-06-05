import XCTest
@testable import Exercis

final class HealthKitCalorieTests: XCTestCase {

    // MARK: - estimatedCalories formula

    func testRunningOneHour75kg() {
        XCTAssertEqual(estimatedCalories(met: 9.0, bodyMass: 75, seconds: 3600), 675, accuracy: 0.01)
    }

    func testWalkingHalfHour80kg() {
        XCTAssertEqual(estimatedCalories(met: 3.5, bodyMass: 80, seconds: 1800), 140, accuracy: 0.01)
    }

    func testStrengthMETFallback75kg() {
        XCTAssertEqual(estimatedCalories(met: 5.5, bodyMass: 75, seconds: 3600), 412.5, accuracy: 0.01)
    }

    func testZeroDurationProducesZeroCalories() {
        XCTAssertEqual(estimatedCalories(met: 9.0, bodyMass: 75, seconds: 0), 0)
    }

    // MARK: - CardioType.met values

    func testMETValuesMatchExpected() {
        let expected: [(CardioType, Double)] = [
            (.crosstrainer,        7.0),
            (.cyclingStationary,   8.0),
            (.rowingMachine,       7.5),
            (.hiking,              5.5),
            (.rucking,             5.5),
            (.running,             9.0),
            (.treadmillRun,        9.0),
            (.walking,             3.5),
            (.treadmillWalk,       3.5),
            (.stairClimber,        8.0),
            (.skiErg,              8.0),
            (.assaultBike,         10.0),
            (.roadCycling,         8.0),
            (.mountainBiking,      8.0),
            (.swimming,            7.0),
            (.crossCountrySkiing,  9.0),
            (.iceSkating,          7.0),
            (.kayaking,            5.0),
            (.canoeing,            5.0),
            (.climbing,            8.0),
            (.boxing,              9.0),
            (.battleRopes,         10.0),
            (.sled,                9.0),
            (.jumpRope,            10.0),
            (.burpees,             10.0),
            (.mountainClimbers,    10.0),
        ]
        for (type, expectedMET) in expected {
            XCTAssertEqual(type.met, expectedMET, accuracy: 0.001, "\(type.rawValue) has wrong MET value")
        }
    }

    func testAllCardioTypesHaveMETValue() {
        for type in CardioType.allCases {
            XCTAssertGreaterThan(type.met, 0, "\(type.rawValue) must have a MET > 0")
        }
    }
}
