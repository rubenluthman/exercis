import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var startDate: Date = Date()
    var healthKitID: UUID? = nil
    var effortScore: Int? = nil
    var programId: UUID? = nil
    var programName: String? = nil

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
    var exerciseDefId: String? = nil
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

enum CardioType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    // Maskiner
    case crosstrainer        = "crosstrainer"
    case cyclingStationary   = "cycling_stationary"
    case rowingMachine       = "rowing_machine"
    case treadmillRun        = "treadmill_run"
    case treadmillWalk       = "treadmill_walk"
    case stairClimber        = "stair_climber"
    case skiErg              = "ski_erg"
    case assaultBike         = "assault_bike"
    // Utomhus
    case running             = "running"
    case walking             = "walking"
    case hiking              = "hiking"
    case roadCycling         = "road_cycling"
    case mountainBiking      = "mountain_biking"
    case swimming            = "swimming"
    // Nordiska
    case crossCountrySkiing  = "cross_country_skiing"
    case iceSkating          = "ice_skating"
    // Vatten
    case kayaking            = "kayaking"
    case canoeing            = "canoeing"
    // Övrigt
    case climbing            = "climbing"
    case boxing              = "boxing"
    case battleRopes         = "battle_ropes"
    case sled                = "sled"
    case rucking             = "rucking"
    // Calisthenics cardio
    case jumpRope            = "jump_rope"
    case burpees             = "burpees"
    case mountainClimbers    = "mountain_climbers"

    var displayName: String {
        switch self {
        case .crosstrainer:       return "Crosstrainer"
        case .cyclingStationary:  return "Cykel"
        case .rowingMachine:      return "Roddmaskin"
        case .treadmillRun:       return "Löpband (löpning)"
        case .treadmillWalk:      return "Löpband (gång)"
        case .stairClimber:       return "Trappmaskin"
        case .skiErg:             return "Stakmaskin"
        case .assaultBike:        return "Assault Bike"
        case .running:            return "Löpning"
        case .walking:            return "Promenad"
        case .hiking:             return "Vandring"
        case .roadCycling:        return "Landsvägscykling"
        case .mountainBiking:     return "Terrängcykling"
        case .swimming:           return "Simning"
        case .crossCountrySkiing: return "Längdskidåkning"
        case .iceSkating:         return "Skridskoåkning"
        case .kayaking:           return "Kajak"
        case .canoeing:           return "Kanot"
        case .climbing:           return "Klättring"
        case .boxing:             return "Boxning"
        case .battleRopes:        return "Battle Ropes"
        case .sled:               return "Släde"
        case .rucking:            return "Rucking"
        case .jumpRope:           return "Hopprep"
        case .burpees:            return "Burpees"
        case .mountainClimbers:   return "Mountain Climbers"
        }
    }
}

@Model
final class CardioSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var startDate: Date = Date()
    var durationMinutes: Double = 0
    var healthKitID: UUID? = nil
    var cardioType: String = CardioType.crosstrainer.rawValue
    var distanceKm: Double? = nil
    var effortScore: Int? = nil
    var elevationGain: Double? = nil

    init(date: Date = Date(), startDate: Date? = nil, durationMinutes: Double,
         cardioType: String = CardioType.crosstrainer.rawValue, distanceKm: Double? = nil) {
        self.date = date
        self.startDate = startDate ?? date.addingTimeInterval(-durationMinutes * 60)
        self.durationMinutes = durationMinutes
        self.cardioType = cardioType
        self.distanceKm = distanceKm
    }
}

// MARK: - Programs

@Model
final class WorkoutProgram {
    var id: UUID = UUID()
    var name: String = ""
    var colorName: String = "paletteIntenseRed"
    var sortIndex: Int = 0
    var isOnTrainingPage: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \ProgramExercise.program)
    var exercises: [ProgramExercise] = []

    init(name: String, colorName: String, sortIndex: Int = 0) {
        self.name = name
        self.colorName = colorName
        self.sortIndex = sortIndex
    }

    var sortedExercises: [ProgramExercise] {
        exercises.sorted { $0.sortIndex < $1.sortIndex }
    }
}

@Model
final class ProgramExercise {
    var exerciseId: String = ""
    var exerciseName: String = ""
    var sortIndex: Int = 0
    var setCount: Int = 3
    var program: WorkoutProgram?

    init(exerciseId: String, exerciseName: String, sortIndex: Int, setCount: Int = 3) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sortIndex = sortIndex
        self.setCount = setCount
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
    var programId: String?

    init(exercises: [ExerciseDraft], startTime: Date,
         collapsedExercises: [Int] = [], programId: String? = nil) {
        self.exercises = exercises
        self.startTime = startTime
        self.collapsedExercises = collapsedExercises
        self.programId = programId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exercises = try c.decode([ExerciseDraft].self, forKey: .exercises)
        startTime = try c.decode(Date.self, forKey: .startTime)
        collapsedExercises = (try? c.decode([Int].self, forKey: .collapsedExercises)) ?? []
        programId = try? c.decode(String.self, forKey: .programId)
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

// MARK: - Migration: exercise names

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

    if current < 4 {
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs where log.name == "Romanian Deadlift (RDL)" {
            log.name = "Romanian Deadlift"
        }
        try? context.save()
    }

    if current < 5 {
        let renames: [String: String] = [
            "Barbell Back Squat": "Squats",
            "Neutral-Grip Incline Dumbbell Bench Press": "Incline Dumbbell Press",
            "Neutral-Grip Lat Pulldown": "Wide-Grip Pulldown"
        ]
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs {
            if let newName = renames[log.name] { log.name = newName }
        }
        try? context.save()
    }

    UserDefaults.standard.set(ExerciseDef.migrationVersion, forKey: key)
}

// MARK: - Migration: CardioType raw values

func migrateCardioTypes(context: ModelContext) {
    let key = "cardioTypeMigrationVersion"
    let current = UserDefaults.standard.integer(forKey: key)
    guard current < 1 else { return }

    let oldToNew: [String: String] = [
        "CROSSTRAINER": "crosstrainer",
        "CYKEL":        "cycling_stationary",
        "RODDMASKIN":   "rowing_machine",
        "VANDRING":     "hiking"
    ]

    let sessions = (try? context.fetch(FetchDescriptor<CardioSession>())) ?? []
    for session in sessions {
        if let newValue = oldToNew[session.cardioType] {
            session.cardioType = newValue
        }
    }
    try? context.save()

    UserDefaults.standard.set(1, forKey: key)
}

// MARK: - Seeder: default programs

func seedDefaultProgramsIfNeeded(context: ModelContext) {
    let existing = (try? context.fetch(FetchDescriptor<WorkoutProgram>())) ?? []
    guard existing.isEmpty else { return }

    let defaults: [(name: String, color: String, exercises: [(id: String, name: String)])] = [
        ("Full Body", "paletteIntenseRed", [
            ("wger_squats",                   "Squats"),
            ("wger_bench_press",              "Bench Press"),
            ("wger_romanian_deadlift",        "Romanian Deadlift"),
            ("wger_bent_over_rowing",         "Bent Over Rowing"),
            ("wger_shoulder_press_dumbbells", "Shoulder Press, Dumbbells")
        ]),
        ("Överkropp", "paletteOrange", [
            ("wger_bench_press",              "Bench Press"),
            ("wger_bent_over_rowing",         "Bent Over Rowing"),
            ("wger_shoulder_press_dumbbells", "Shoulder Press, Dumbbells"),
            ("wger_pullups",                  "Pull-Ups"),
            ("wger_lateral_raises",           "Lateral Raises")
        ]),
        ("Underkropp", "paletteYellow", [
            ("wger_squats",                 "Squats"),
            ("wger_romanian_deadlift",      "Romanian Deadlift"),
            ("wger_leg_presses_wide",       "Leg Presses (Wide)"),
            ("wger_leg_curls_laying",       "Leg Curls (Laying)"),
            ("wger_standing_calf_raises",   "Standing Calf Raises")
        ]),
        ("Push", "paletteLime", [
            ("wger_bench_press",                          "Bench Press"),
            ("wger_incline_dumbbell_press",               "Incline Dumbbell Press"),
            ("wger_shoulder_press_dumbbells",             "Shoulder Press, Dumbbells"),
            ("wger_lateral_raises",                       "Lateral Raises"),
            ("wger_triceps_extensions_on_cable_with_bar", "Triceps Extensions On Cable With Bar")
        ]),
        ("Pull", "paletteGreen", [
            ("wger_deadlifts",                   "Deadlifts"),
            ("wger_pullups",                     "Pull-Ups"),
            ("wger_rowing_seated",               "Rowing, Seated"),
            ("wger_lat_pull_down_straight_back", "Lat Pull Down (Straight Back)"),
            ("wger_biceps_curls_with_dumbbell",  "Biceps Curls With Dumbbell")
        ]),
        ("Legs", "paletteTeal", [
            ("wger_squats",             "Squats"),
            ("wger_romanian_deadlift",  "Romanian Deadlift"),
            ("wger_leg_presses_wide",   "Leg Presses (Wide)"),
            ("wger_leg_extension",      "Leg Extension"),
            ("wger_leg_curls_laying",   "Leg Curls (Laying)")
        ]),
        ("Bodyweight", "paletteCyan", [
            ("wger_body_squats",         "Body Squats"),
            ("wger_push_ups",            "Push Ups"),
            ("wger_bodyweight_lunges",   "Bodyweight Lunges"),
            ("wger_superman",            "Superman"),
            ("wger_plank",               "Plank")
        ])
    ]

    for (i, def) in defaults.enumerated() {
        let program = WorkoutProgram(name: def.name, colorName: def.color, sortIndex: i)
        context.insert(program)
        for (j, ex) in def.exercises.enumerated() {
            let pe = ProgramExercise(exerciseId: ex.id, exerciseName: ex.name, sortIndex: j)
            pe.program = program
            context.insert(pe)
        }
    }
    try? context.save()
}
