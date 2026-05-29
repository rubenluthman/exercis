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
    var effortScore: Int? = nil

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
    let displayName: String
    let repRange: String
    let videoURL: String
    var aliases: [String] = []

    init(name: String, displayName: String? = nil, repRange: String, videoURL: String, aliases: [String] = []) {
        self.name = name
        self.displayName = displayName ?? name
        self.repRange = repRange
        self.videoURL = videoURL
        self.aliases = aliases
    }

    static let all: [ExerciseDef] = [
        ExerciseDef(name: "Barbell Back Squat",
                    repRange: "5–8 REPS",
                    videoURL: "https://www.youtube.com/watch?v=R2dMsNhN3DE",
                    aliases: ["Safety Bar Squat"]),
        ExerciseDef(name: "Neutral-Grip Incline Dumbbell Bench Press",
                    displayName: "Incline Dumbbell Bench Press",
                    repRange: "6–10 REPS",
                    videoURL: "https://www.youtube.com/watch?v=8nNi8jbbUPE",
                    aliases: ["Incline DB Bench Press"]),
        ExerciseDef(name: "Romanian Deadlift (RDL)",
                    repRange: "6–8 REPS",
                    videoURL: "https://www.youtube.com/watch?v=-m45n1_x32E",
                    aliases: ["Romanian Deadlift"]),
        ExerciseDef(name: "Seated Cable Row",
                    repRange: "8–12 REPS",
                    videoURL: "https://www.muscleandstrength.com/exercises/seated-row.html"),
        ExerciseDef(name: "Neutral-Grip Lat Pulldown",
                    displayName: "Lat Pulldown",
                    repRange: "8–12 REPS",
                    videoURL: "https://www.youtube.com/watch?v=iKrKgWR9wbY",
                    aliases: ["Lat Pulldown"]),
    ]

    // Pensionerade övningar — tas bort från `all` men data bevaras i historik.
    // Lägg till här när en övning byts ut mot en ny.
    static let retired: [ExerciseDef] = []

    static func find(name: String) -> ExerciseDef? {
        all.first(where: { $0.name == name }) ?? retired.first(where: { $0.name == name })
    }

    // Bump this each time exercises change and update migrateExerciseNames accordingly.
    static let migrationVersion = 3
}

func migrateExerciseNames(context: ModelContext) {
    let key = "exerciseNameMigrationVersion"
    var current = UserDefaults.standard.integer(forKey: key)
    guard current < ExerciseDef.migrationVersion else { return }

    if current < 2 {
        let aliasMap = Dictionary(uniqueKeysWithValues:
            ExerciseDef.all.flatMap { def in def.aliases.map { ($0, def.name) } }
        )
        if !aliasMap.isEmpty {
            let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
            for log in logs {
                if let newName = aliasMap[log.name] { log.name = newName }
            }
            try? context.save()
        }
        current = 2
    }

    if current < 3 {
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs where log.name == "Chest-Supported Row" {
            context.delete(log)
        }
        try? context.save()
    }

    UserDefaults.standard.set(ExerciseDef.migrationVersion, forKey: key)
}
