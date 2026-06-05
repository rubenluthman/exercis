import Foundation
import SwiftData

func buildWidgetSnapshot(
    workoutSessions: [WorkoutSession],
    cardioSessions: [CardioSession],
    programs: [WorkoutProgram]
) -> WidgetSnapshot {
    let streak = computeStreak(workouts: workoutSessions, cardio: cardioSessions)
    let lastWorkout = workoutSessions.sorted(by: { $0.date > $1.date }).first
    let lastCardio  = cardioSessions.sorted(by: { $0.date > $1.date }).first

    var lastDate: Date? = nil
    var lastProgram: String? = nil
    var lastExerciseCount = 0

    if let w = lastWorkout, let c = lastCardio {
        if w.date > c.date {
            lastDate = w.date
            lastProgram = w.programName
            lastExerciseCount = w.exerciseLogs.count
        } else {
            lastDate = c.date
            lastProgram = CardioType(rawValue: c.cardioType)?.displayName ?? c.cardioType
            lastExerciseCount = 0
        }
    } else if let w = lastWorkout {
        lastDate = w.date
        lastProgram = w.programName
        lastExerciseCount = w.exerciseLogs.count
    } else if let c = lastCardio {
        lastDate = c.date
        lastProgram = CardioType(rawValue: c.cardioType)?.displayName ?? c.cardioType
    }

    let activePrograms = programs.filter(\.isOnTrainingPage).sorted(by: { $0.sortIndex < $1.sortIndex })
    let nextProgram: WorkoutProgram?
    if let lastId = workoutSessions.sorted(by: { $0.date > $1.date }).first?.programId {
        let idx = activePrograms.firstIndex(where: { $0.id == lastId }) ?? -1
        nextProgram = activePrograms.isEmpty ? nil : activePrograms[(idx + 1) % activePrograms.count]
    } else {
        nextProgram = activePrograms.first
    }

    return WidgetSnapshot(
        streak: streak,
        lastSessionDate: lastDate,
        lastSessionProgramName: lastProgram,
        lastSessionExerciseCount: lastExerciseCount,
        nextProgramName: nextProgram?.name,
        nextProgramColorName: nextProgram?.colorName
    )
}

private func computeStreak(workouts: [WorkoutSession], cardio: [CardioSession]) -> Int {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())

    var activeDays = Set<Date>()
    for s in workouts { activeDays.insert(cal.startOfDay(for: s.date)) }
    for s in cardio   { activeDays.insert(cal.startOfDay(for: s.date)) }

    var streak = 0
    var cursor = today
    // Allow today to count even if not yet trained
    if !activeDays.contains(cursor) {
        cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }
    while activeDays.contains(cursor) {
        streak += 1
        cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }
    return streak
}
