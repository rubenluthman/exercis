import XCTest
@testable import Exercis

@MainActor
final class WorkoutDraftCodableTests: XCTestCase {

    private let set1 = WorkoutDraft.SetDraft(weight: "80", reps: "8")
    private let set2 = WorkoutDraft.SetDraft(weight: "82.5", reps: "6")

    private func makeDraft(
        collapsed: [Int] = [],
        programId: String? = nil
    ) -> WorkoutDraft {
        let ex = WorkoutDraft.ExerciseDraft(
            name: "Squat",
            sets: [set1, set2],
            shouldIncrease: true,
            previousMaxWeight: 80
        )
        return WorkoutDraft(
            exercises: [ex],
            startTime: Date(timeIntervalSinceReferenceDate: 1_000_000),
            collapsedExercises: collapsed,
            programId: programId
        )
    }

    // MARK: Round-trip

    func testRoundTripPreservesExercises() throws {
        let draft = makeDraft()
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(WorkoutDraft.self, from: data)
        XCTAssertEqual(decoded.exercises.count, 1)
        XCTAssertEqual(decoded.exercises[0].name, "Squat")
        XCTAssertEqual(decoded.exercises[0].sets.count, 2)
        XCTAssertEqual(decoded.exercises[0].sets[0].weight, "80")
        XCTAssertEqual(decoded.exercises[0].sets[1].reps, "6")
    }

    func testRoundTripPreservesStartTime() throws {
        let draft = makeDraft()
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(WorkoutDraft.self, from: data)
        XCTAssertEqual(decoded.startTime.timeIntervalSinceReferenceDate,
                       draft.startTime.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }

    func testRoundTripPreservesCollapsedExercises() throws {
        let draft = makeDraft(collapsed: [0, 2])
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(WorkoutDraft.self, from: data)
        XCTAssertEqual(decoded.collapsedExercises, [0, 2])
    }

    func testRoundTripPreservesProgramId() throws {
        let draft = makeDraft(programId: "abc-123")
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(WorkoutDraft.self, from: data)
        XCTAssertEqual(decoded.programId, "abc-123")
    }

    // MARK: Backward compatibility — old drafts without newer fields

    func testDecodingWithoutCollapsedExercisesDefaultsToEmpty() throws {
        let json = """
        {
            "exercises": [{
                "name": "Squat",
                "sets": [{"weight": "80", "reps": "5"}],
                "shouldIncrease": false,
                "previousMaxWeight": 80
            }],
            "startTime": 1000000
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WorkoutDraft.self, from: data)
        XCTAssertEqual(decoded.collapsedExercises, [])
    }

    func testDecodingWithoutProgramIdDefaultsToNil() throws {
        let json = """
        {
            "exercises": [],
            "startTime": 1000000,
            "collapsedExercises": []
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WorkoutDraft.self, from: data)
        XCTAssertNil(decoded.programId)
    }

    func testDecodingWithoutBothNewFieldsDoesNotCrash() throws {
        let json = """
        {
            "exercises": [],
            "startTime": 1000000
        }
        """
        let data = json.data(using: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(WorkoutDraft.self, from: data))
    }
}
