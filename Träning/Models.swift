import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var healthKitID: UUID? = nil
    var effortScore: Int? = nil

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog] = []

    init(date: Date = Date()) {
        self.date = date
    }
}

@Model
final class ExerciseLog {
    var name: String = ""
    var orderIndex: Int = 0
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
    var sets: [SetLog] = []

    init(name: String, orderIndex: Int) {
        self.name = name
        self.orderIndex = orderIndex
    }
}

@Model
final class SetLog {
    var setNumber: Int = 0
    var weight: Double = 0
    var reps: Int = 0
    var exerciseLog: ExerciseLog?

    init(setNumber: Int, weight: Double, reps: Int) {
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
    }
}

// MARK: - Cardio

enum CardioType: String, Codable, CaseIterable {
    case crosstrainer = "CROSSTRAINER"
    case cykel        = "CYKEL"
    case roddmaskin   = "RODDMASKIN"
}

@Model
final class CardioSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var durationMinutes: Double = 0
    var healthKitID: UUID? = nil
    var cardioType: String = CardioType.crosstrainer.rawValue
    var distanceKm: Double? = nil

    init(date: Date = Date(), durationMinutes: Double, cardioType: String = CardioType.crosstrainer.rawValue, distanceKm: Double? = nil) {
        self.date = date
        self.durationMinutes = durationMinutes
        self.cardioType = cardioType
        self.distanceKm = distanceKm
    }
}

// MARK: - Draft

struct WorkoutDraft: Codable {
    struct SetDraft: Codable { var weight: String; var reps: String }
    struct ExerciseDraft: Codable {
        var name: String
        var sets: [SetDraft]
        var shouldIncrease: Bool
        var previousMaxWeight: Double
    }
    var exercises: [ExerciseDraft]
    var startTime: Date
    var collapsedExercises: [Int]

    init(exercises: [ExerciseDraft], startTime: Date, collapsedExercises: [Int] = []) {
        self.exercises = exercises
        self.startTime = startTime
        self.collapsedExercises = collapsedExercises
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exercises = try c.decode([ExerciseDraft].self, forKey: .exercises)
        startTime = try c.decode(Date.self, forKey: .startTime)
        collapsedExercises = (try? c.decode([Int].self, forKey: .collapsedExercises)) ?? []
    }
}

extension UserDefaults {
    private static let draftKey = "workoutDraft"

    func saveDraft(_ draft: WorkoutDraft?) {
        if let draft, let data = try? JSONEncoder().encode(draft) {
            set(data, forKey: Self.draftKey)
        } else {
            removeObject(forKey: Self.draftKey)
        }
    }

    func loadDraft() -> WorkoutDraft? {
        guard let data = data(forKey: Self.draftKey) else { return nil }
        return try? JSONDecoder().decode(WorkoutDraft.self, from: data)
    }
}

// MARK: - Exercise Definitions

struct ExerciseDef {
    let name: String
    let repRange: String
    let youtubeID: String

    static let all: [ExerciseDef] = [
        ExerciseDef(name: "Safety Bar Squat",                    repRange: "5–8 REPS",  youtubeID: "OuvfDyf28eU"),
        ExerciseDef(name: "Romanian Deadlift",                   repRange: "6–8 REPS",  youtubeID: "-m45n1_x32E"),
        ExerciseDef(name: "Incline DB Bench Press", repRange: "6–10 REPS", youtubeID: "8nNi8jbbUPE"),
        ExerciseDef(name: "Chest-Supported Row",    repRange: "8–10 REPS", youtubeID: "oKNjFM1bxAs"),
        ExerciseDef(name: "Lat Pulldown",           repRange: "8–12 REPS", youtubeID: "iKrKgWR9wbY"),
    ]
}
