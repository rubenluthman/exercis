import XCTest
import SwiftData
@testable import Exercis

@MainActor
final class ProgramSeederTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUpWithError() throws {
        container = try makeTestContainer()
        UserDefaults.standard.removeObject(forKey: "hasSeededPrograms")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "hasSeededPrograms")
    }

    func testSeederCreatesSevenPrograms() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        XCTAssertEqual(programs.count, 7)
    }

    func testSeederCreatesExpectedNames() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        let names = Set(programs.map(\.name))
        XCTAssertEqual(names, ["Full Body", "Överkropp", "Underkropp", "Push", "Pull", "Legs", "Bodyweight"])
    }

    func testProgramConstraints() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        let byName = Dictionary(uniqueKeysWithValues: programs.map { ($0.name, $0.programConstraint) })
        XCTAssertEqual(byName["Full Body"],   "")
        XCTAssertEqual(byName["Överkropp"],   "upper")
        XCTAssertEqual(byName["Underkropp"],  "legs")
        XCTAssertEqual(byName["Push"],        "push")
        XCTAssertEqual(byName["Pull"],        "pull")
        XCTAssertEqual(byName["Legs"],        "legs")
        XCTAssertEqual(byName["Bodyweight"],  "bodyweight")
    }

    func testEachProgramHasFiveExercises() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        for program in programs {
            XCTAssertEqual(program.exercises.count, 5, "\(program.name) should have 5 exercises")
        }
    }

    func testProgramsAreNotOnTrainingPageByDefault() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        for program in programs {
            XCTAssertFalse(program.isOnTrainingPage, "\(program.name) should not be on training page after seeding")
        }
    }

    func testSeederRunsOnlyOnce() throws {
        seedDefaultProgramsIfNeeded(context: context)
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        XCTAssertEqual(programs.count, 7, "Second seed should be a no-op")
    }

    func testExerciseSortIndexIsOrdered() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>())
        for program in programs {
            let indices = program.sortedExercises.map(\.sortIndex)
            XCTAssertEqual(indices, Array(0..<indices.count), "\(program.name) exercise sortIndex should be 0-based sequential")
        }
    }

    func testProgramSortIndexIsOrdered() throws {
        seedDefaultProgramsIfNeeded(context: context)
        let programs = try context.fetch(FetchDescriptor<WorkoutProgram>(sortBy: [SortDescriptor(\.sortIndex)]))
        let indices = programs.map(\.sortIndex)
        XCTAssertEqual(indices, Array(0..<7))
    }
}
