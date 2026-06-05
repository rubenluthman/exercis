import XCTest
import SwiftData
@testable import Exercis

@MainActor
final class DataMigrationTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext { container.mainContext }

    override func setUpWithError() throws {
        container = try makeTestContainer()
        // Reset migration flags so migrations run fresh each test
        UserDefaults.standard.removeObject(forKey: "cardioTypeMigrationVersion")
        UserDefaults.standard.removeObject(forKey: "exerciseNameMigrationVersion")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "cardioTypeMigrationVersion")
        UserDefaults.standard.removeObject(forKey: "exerciseNameMigrationVersion")
        container = nil
    }

    // MARK: migrateCardioTypes

    func testMigratesKnownOldValues() throws {
        let pairs: [(old: String, new: String)] = [
            ("CROSSTRAINER", "crosstrainer"),
            ("CYKEL",        "cycling_stationary"),
            ("RODDMASKIN",   "rowing_machine"),
            ("VANDRING",     "hiking")
        ]
        for (old, _) in pairs {
            let s = CardioSession(date: Date(), durationMinutes: 30, cardioType: old)
            context.insert(s)
        }
        try context.save()

        migrateCardioTypes(context: context)

        let sessions = try context.fetch(FetchDescriptor<CardioSession>())
        let types = Set(sessions.map(\.cardioType))
        for (_, new) in pairs {
            XCTAssertTrue(types.contains(new), "Expected \(new) after migration")
        }
        for (old, _) in pairs {
            XCTAssertFalse(types.contains(old), "Old value \(old) should be gone")
        }
    }

    func testUnknownValueIsLeftUntouched() throws {
        let s = CardioSession(date: Date(), durationMinutes: 20, cardioType: "running")
        context.insert(s)
        try context.save()

        migrateCardioTypes(context: context)

        let sessions = try context.fetch(FetchDescriptor<CardioSession>())
        XCTAssertEqual(sessions.first?.cardioType, "running")
    }

    func testMigrationRunsOnlyOnce() throws {
        let s = CardioSession(date: Date(), durationMinutes: 20, cardioType: "CROSSTRAINER")
        context.insert(s)
        try context.save()

        migrateCardioTypes(context: context)
        // Manually revert to old value to simulate a second run
        let sessions = try context.fetch(FetchDescriptor<CardioSession>())
        sessions.first?.cardioType = "CROSSTRAINER"
        try context.save()

        migrateCardioTypes(context: context)  // should be a no-op

        let after = try context.fetch(FetchDescriptor<CardioSession>())
        XCTAssertEqual(after.first?.cardioType, "CROSSTRAINER", "Second run should not touch data")
    }

    // MARK: migrateExerciseNames

    func testV5RenamesKnownExercises() throws {
        let renames: [String: String] = [
            "Barbell Back Squat": "Squats",
            "Neutral-Grip Incline Dumbbell Bench Press": "Incline Dumbbell Press",
            "Neutral-Grip Lat Pulldown": "Wide-Grip Pulldown"
        ]
        let session = WorkoutSession()
        context.insert(session)
        for (i, oldName) in renames.keys.enumerated() {
            let log = ExerciseLog(name: oldName, orderIndex: i)
            log.session = session
            context.insert(log)
        }
        try context.save()

        migrateExerciseNames(context: context)

        let logs = try context.fetch(FetchDescriptor<ExerciseLog>())
        let names = Set(logs.map(\.name))
        for (old, new) in renames {
            XCTAssertFalse(names.contains(old), "Old name \(old) should be renamed")
            XCTAssertTrue(names.contains(new), "New name \(new) should exist")
        }
    }

    func testV3DeletesChestSupportedRow() throws {
        let session = WorkoutSession()
        context.insert(session)
        let log = ExerciseLog(name: "Chest-Supported Row", orderIndex: 0)
        log.session = session
        context.insert(log)
        try context.save()

        migrateExerciseNames(context: context)

        let logs = try context.fetch(FetchDescriptor<ExerciseLog>())
        XCTAssertFalse(logs.map(\.name).contains("Chest-Supported Row"))
    }

    func testV4RenamesRomanianDeadlift() throws {
        let session = WorkoutSession()
        context.insert(session)
        let log = ExerciseLog(name: "Romanian Deadlift (RDL)", orderIndex: 0)
        log.session = session
        context.insert(log)
        try context.save()

        migrateExerciseNames(context: context)

        let logs = try context.fetch(FetchDescriptor<ExerciseLog>())
        XCTAssertTrue(logs.map(\.name).contains("Romanian Deadlift"))
        XCTAssertFalse(logs.map(\.name).contains("Romanian Deadlift (RDL)"))
    }

    func testUnknownExerciseNameIsUntouched() throws {
        let session = WorkoutSession()
        context.insert(session)
        let log = ExerciseLog(name: "ZZZ_NonexistentExercise", orderIndex: 0)
        log.session = session
        context.insert(log)
        try context.save()

        migrateExerciseNames(context: context)

        let logs = try context.fetch(FetchDescriptor<ExerciseLog>())
        XCTAssertTrue(logs.map(\.name).contains("ZZZ_NonexistentExercise"))
    }
}
