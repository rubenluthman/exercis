import XCTest
import HealthKit
@testable import Exercis

final class CardioTypeMappingTests: XCTestCase {

    // MARK: tracksElevation

    func testTracksElevationTrueForExpectedTypes() {
        let expected: Set<CardioType> = [
            .hiking, .running, .walking, .roadCycling,
            .mountainBiking, .crossCountrySkiing, .rucking, .climbing
        ]
        for type in expected {
            XCTAssertTrue(type.tracksElevation, "\(type) should track elevation")
        }
    }

    func testTracksElevationFalseForRemainingTypes() {
        let tracksElevation: Set<CardioType> = [
            .hiking, .running, .walking, .roadCycling,
            .mountainBiking, .crossCountrySkiing, .rucking, .climbing
        ]
        for type in CardioType.allCases where !tracksElevation.contains(type) {
            XCTAssertFalse(type.tracksElevation, "\(type) should NOT track elevation")
        }
    }

    func testAllCasesHaveExplicitElevationValue() {
        // Ensures no new case is silently defaulting — every case must be covered
        XCTAssertEqual(
            CardioType.allCases.filter { $0.tracksElevation }.count,
            8,
            "Exactly 8 types should track elevation"
        )
    }

    // MARK: hkActivityType

    func testHKActivityTypeMappings() {
        let expected: [(CardioType, HKWorkoutActivityType)] = [
            (.crosstrainer,        .elliptical),
            (.cyclingStationary,   .cycling),
            (.rowingMachine,       .rowing),
            (.treadmillRun,        .running),
            (.treadmillWalk,       .walking),
            (.stairClimber,        .stairClimbing),
            (.skiErg,              .rowing),
            (.assaultBike,         .cycling),
            (.running,             .running),
            (.walking,             .walking),
            (.hiking,              .hiking),
            (.roadCycling,         .cycling),
            (.mountainBiking,      .cycling),
            (.swimming,            .swimming),
            (.crossCountrySkiing,  .crossCountrySkiing),
            (.iceSkating,          .skatingSports),
            (.kayaking,            .rowing),
            (.canoeing,            .rowing),
            (.climbing,            .climbing),
            (.boxing,              .boxing),
            (.battleRopes,         .highIntensityIntervalTraining),
            (.sled,                .functionalStrengthTraining),
            (.rucking,             .hiking),
            (.jumpRope,            .jumpRope),
            (.burpees,             .highIntensityIntervalTraining),
            (.mountainClimbers,    .highIntensityIntervalTraining),
        ]
        for (type, expectedHK) in expected {
            XCTAssertEqual(type.hkActivityType, expectedHK,
                           "\(type).hkActivityType should be \(expectedHK)")
        }
    }

    func testAllCasesHaveHKMapping() {
        // Ensures no new CardioType case is missing from the switch
        for type in CardioType.allCases {
            XCTAssertNotNil(type.hkActivityType,
                            "\(type) must have an hkActivityType")
        }
    }
}
