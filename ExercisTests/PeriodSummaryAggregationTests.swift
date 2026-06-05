import XCTest
import SwiftData
@testable import Exercis

final class PeriodSummaryAggregationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    // Mirrors PeriodSummarySheet.totalVolume
    private func totalVolume(_ sessions: [WorkoutSession]) -> Double {
        sessions.reduce(0.0) { t, s in
            t + s.exerciseLogs.reduce(0.0) { lt, l in
                lt + l.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            }
        }
    }

    // Mirrors PeriodSummarySheet.totalMinutes
    private func totalMinutes(_ sessions: [CardioSession]) -> Double {
        sessions.reduce(0.0) { $0 + $1.durationMinutes }
    }

    // Mirrors PeriodSummarySheet.volumeText
    private func volumeText(_ vol: Double) -> (String, String?) {
        guard vol > 0 else { return ("—", nil) }
        if vol >= 1000 { return (formatWeight(vol / 1000), " TON") }
        return (formatWeight(vol), "kg")
    }

    // MARK: - Volume

    func testVolumeEmpty() {
        XCTAssertEqual(totalVolume([]), 0)
    }

    func testVolumeSingleSet() throws {
        let session = WorkoutSession(date: Date())
        context.insert(session)
        let log = ExerciseLog(name: "Squat", orderIndex: 0)
        log.session = session
        context.insert(log)
        let set = SetLog(setNumber: 1, weight: 100, reps: 5)
        set.exerciseLog = log
        context.insert(set)

        XCTAssertEqual(totalVolume([session]), 500, accuracy: 0.001)
    }

    func testVolumeMultipleSetsAndExercises() throws {
        let session = WorkoutSession(date: Date())
        context.insert(session)

        let log1 = ExerciseLog(name: "Squat", orderIndex: 0)
        log1.session = session; context.insert(log1)
        let s1 = SetLog(setNumber: 1, weight: 100, reps: 5); s1.exerciseLog = log1; context.insert(s1)
        let s2 = SetLog(setNumber: 2, weight: 100, reps: 5); s2.exerciseLog = log1; context.insert(s2)

        let log2 = ExerciseLog(name: "Bench Press", orderIndex: 1)
        log2.session = session; context.insert(log2)
        let s3 = SetLog(setNumber: 1, weight: 80, reps: 8); s3.exerciseLog = log2; context.insert(s3)

        // 100×5 + 100×5 + 80×8 = 500 + 500 + 640 = 1640
        XCTAssertEqual(totalVolume([session]), 1640, accuracy: 0.001)
    }

    func testVolumeAcrossMultipleSessions() throws {
        let s1 = WorkoutSession(date: Date()); context.insert(s1)
        let l1 = ExerciseLog(name: "Squat", orderIndex: 0); l1.session = s1; context.insert(l1)
        let set1 = SetLog(setNumber: 1, weight: 100, reps: 5); set1.exerciseLog = l1; context.insert(set1)

        let s2 = WorkoutSession(date: Date()); context.insert(s2)
        let l2 = ExerciseLog(name: "Squat", orderIndex: 0); l2.session = s2; context.insert(l2)
        let set2 = SetLog(setNumber: 1, weight: 120, reps: 3); set2.exerciseLog = l2; context.insert(set2)

        // 500 + 360 = 860
        XCTAssertEqual(totalVolume([s1, s2]), 860, accuracy: 0.001)
    }

    // MARK: - Volume text formatting

    func testVolumeBelowThousandShowsKg() {
        let (value, unit) = volumeText(500)
        XCTAssertFalse(value == "—")
        XCTAssertEqual(unit, "kg")
    }

    func testVolumeAtThousandShowsTon() {
        let (value, unit) = volumeText(1000)
        XCTAssertFalse(value == "—")
        XCTAssertEqual(unit, " TON")
    }

    func testVolumeZeroShowsDash() {
        let (value, unit) = volumeText(0)
        XCTAssertEqual(value, "—")
        XCTAssertNil(unit)
    }

    func testVolumeTonDividesByThousand() {
        let (value, _) = volumeText(2000)
        XCTAssertEqual(value, formatWeight(2.0))
    }

    // MARK: - Cardio minutes

    func testCardioMinutesEmpty() {
        XCTAssertEqual(totalMinutes([]), 0)
    }

    func testCardioMinutesSingleSession() {
        let session = CardioSession(date: Date(), cardioType: CardioType.running.rawValue, durationMinutes: 45)
        XCTAssertEqual(totalMinutes([session]), 45, accuracy: 0.001)
    }

    func testCardioMinutesMultipleSessions() {
        let s1 = CardioSession(date: Date(), cardioType: CardioType.running.rawValue, durationMinutes: 30)
        let s2 = CardioSession(date: Date(), cardioType: CardioType.cycling_stationary.rawValue, durationMinutes: 45)
        XCTAssertEqual(totalMinutes([s1, s2]), 75, accuracy: 0.001)
    }

    func testCardioMinutesFractional() {
        let s = CardioSession(date: Date(), cardioType: CardioType.running.rawValue, durationMinutes: 22.5)
        XCTAssertEqual(totalMinutes([s]), 22.5, accuracy: 0.001)
    }
}
