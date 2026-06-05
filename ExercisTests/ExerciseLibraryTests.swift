import XCTest
@testable import Exercis

final class ExerciseLibraryTests: XCTestCase {

    // MARK: Loading

    func testLoads186IncludedExercises() {
        XCTAssertEqual(ExerciseDef.all.count, 186)
    }

    func testAllExercisesHaveNonEmptyId() {
        for def in ExerciseDef.all {
            XCTAssertFalse(def.id.isEmpty, "Exercise '\(def.name)' has empty id")
        }
    }

    func testAllExercisesHaveNonEmptyName() {
        for def in ExerciseDef.all {
            XCTAssertFalse(def.name.isEmpty, "Exercise with id '\(def.id)' has empty name")
        }
    }

    func testAllIdsAreUnique() {
        let ids = ExerciseDef.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate exercise ids found")
    }

    func testAllNamesAreUnique() {
        let names = ExerciseDef.all.map(\.name)
        let dupes = Dictionary(grouping: names) { $0 }.filter { $1.count > 1 }.keys
        XCTAssertTrue(dupes.isEmpty, "Duplicate exercise names: \(dupes.sorted())")
    }

    func testRepRangesAreValid() {
        for def in ExerciseDef.all {
            XCTAssertLessThanOrEqual(def.repRangeMin, def.repRangeMax,
                "\(def.name): repRangeMin > repRangeMax")
            XCTAssertGreaterThan(def.repRangeMin, 0, "\(def.name): repRangeMin must be > 0")
        }
    }

    // MARK: find(name:)

    func testFindByExactName() {
        let def = ExerciseDef.find(name: "Squats")
        XCTAssertNotNil(def)
        XCTAssertEqual(def?.name, "Squats")
    }

    func testFindByNameCaseSensitive() {
        XCTAssertNil(ExerciseDef.find(name: "squats"))
    }

    func testFindNonexistentNameReturnsNil() {
        XCTAssertNil(ExerciseDef.find(name: "ZZZ_Fictional"))
    }

    // MARK: find(id:)

    func testFindById() {
        guard let first = ExerciseDef.all.first else { return XCTFail("No exercises loaded") }
        let found = ExerciseDef.find(id: first.id)
        XCTAssertEqual(found?.id, first.id)
    }

    func testFindByNonexistentIdReturnsNil() {
        XCTAssertNil(ExerciseDef.find(id: "zzz_nonexistent"))
    }

    // MARK: Aliases — no duplicates

    func testNoAliasIsSharedAcrossExercisesWithSameName() {
        var seen: [String: String] = [:]
        for def in ExerciseDef.all {
            for alias in def.aliases {
                if let existing = seen[alias] {
                    // Duplicate alias is allowed but should not match the same name
                    XCTAssertNotEqual(existing, def.name,
                        "Alias '\(alias)' points to two exercises with same name")
                } else {
                    seen[alias] = def.name
                }
            }
        }
    }

    // MARK: BodyLimitation contraindications

    func testKneeContraindicationsAreNonEmpty() {
        XCTAssertFalse(BodyLimitation.knee.contraindications.isEmpty)
    }

    func testAtLeastOneExerciseHasKneeContraindication() {
        let kneeContra = Set(BodyLimitation.knee.contraindications)
        let affected = ExerciseDef.all.filter { !Set($0.contraindications).isDisjoint(with: kneeContra) }
        XCTAssertFalse(affected.isEmpty, "No exercises have knee contraindications")
    }

    func testAllBodyLimitationsHaveContraindications() {
        for limitation in BodyLimitation.allCases {
            XCTAssertFalse(limitation.contraindications.isEmpty,
                "\(limitation) has no contraindications defined")
        }
    }

    // MARK: ProgramConstraint filtering

    func testPushConstraintMatchesPushExercises() {
        let pushExercises = ExerciseDef.all.filter { ProgramConstraint.push.matches($0) }
        XCTAssertFalse(pushExercises.isEmpty, "No push exercises found")
        for def in pushExercises {
            XCTAssertEqual(def.movement, "push", "\(def.name) matched push but has movement '\(def.movement ?? "nil")'")
        }
    }

    func testPullConstraintMatchesPullExercises() {
        let pullExercises = ExerciseDef.all.filter { ProgramConstraint.pull.matches($0) }
        XCTAssertFalse(pullExercises.isEmpty, "No pull exercises found")
        for def in pullExercises {
            XCTAssertEqual(def.movement, "pull", "\(def.name) matched pull but has movement '\(def.movement ?? "nil")'")
        }
    }

    func testNoneConstraintMatchesAll() {
        let all = ExerciseDef.all.filter { ProgramConstraint.none.matches($0) }
        XCTAssertEqual(all.count, ExerciseDef.all.count)
    }

    func testBodyweightConstraintOnlyUsesBodyweightEquipment() {
        let bwEquipment = Set(["bodyweight", "pull_up_bar", "dip_bar"])
        let bwExercises = ExerciseDef.all.filter { ProgramConstraint.bodyweight.matches($0) }
        XCTAssertFalse(bwExercises.isEmpty)
        for def in bwExercises {
            XCTAssertTrue(def.equipment.allSatisfy { bwEquipment.contains($0) },
                "\(def.name) matched bodyweight but uses non-bodyweight equipment: \(def.equipment)")
        }
    }

    // MARK: MuscleGroup filtering

    func testChestGroupMatchesChestExercises() {
        let chestExercises = ExerciseDef.all.filter { MuscleGroup.chest.matches($0) }
        XCTAssertFalse(chestExercises.isEmpty)
        for def in chestExercises {
            XCTAssertTrue(def.primaryMuscles.contains("chest"),
                "\(def.name) matched chest but primaryMuscles: \(def.primaryMuscles)")
        }
    }
}
