import Foundation
import SwiftData
import HealthKit
import OSLog

private let logger = Logger(subsystem: "com.exercis", category: "SwiftData")

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

    var tracksElevation: Bool {
        switch self {
        case .hiking, .running, .walking, .roadCycling, .mountainBiking,
             .crossCountrySkiing, .rucking, .climbing:
            return true
        default:
            return false
        }
    }

    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .crosstrainer:                       return .elliptical
        case .cyclingStationary, .assaultBike,
             .roadCycling, .mountainBiking:       return .cycling
        case .rowingMachine, .skiErg,
             .kayaking, .canoeing:                return .rowing
        case .hiking, .rucking:                   return .hiking
        case .running, .treadmillRun:             return .running
        case .walking, .treadmillWalk:            return .walking
        case .stairClimber:                       return .stairClimbing
        case .swimming:                           return .swimming
        case .crossCountrySkiing:                 return .crossCountrySkiing
        case .iceSkating:                         return .skatingSports
        case .climbing:                           return .climbing
        case .boxing:                             return .boxing
        case .battleRopes, .burpees,
             .mountainClimbers:                   return .highIntensityIntervalTraining
        case .sled:                               return .functionalStrengthTraining
        case .jumpRope:                           return .jumpRope
        }
    }

    var met: Double {
        switch self {
        case .crosstrainer:                        return 7.0
        case .cyclingStationary:                   return 8.0
        case .rowingMachine:                       return 7.5
        case .hiking, .rucking:                    return 5.5
        case .running, .treadmillRun:              return 9.0
        case .walking, .treadmillWalk:             return 3.5
        case .stairClimber:                        return 8.0
        case .skiErg:                              return 8.0
        case .assaultBike:                         return 10.0
        case .roadCycling, .mountainBiking:        return 8.0
        case .swimming:                            return 7.0
        case .crossCountrySkiing:                  return 9.0
        case .iceSkating:                          return 7.0
        case .kayaking, .canoeing:                 return 5.0
        case .climbing:                            return 8.0
        case .boxing:                              return 9.0
        case .battleRopes:                         return 10.0
        case .sled:                                return 9.0
        case .jumpRope:                            return 10.0
        case .burpees, .mountainClimbers:          return 10.0
        }
    }

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
    var programConstraint: String = ""
    var useFixedReps: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \ProgramExercise.program)
    var exercises: [ProgramExercise] = []

    init(name: String, colorName: String, sortIndex: Int = 0, programConstraint: String = "") {
        self.name = name
        self.colorName = colorName
        self.sortIndex = sortIndex
        self.programConstraint = programConstraint
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
    var fixedReps: Int = 0
    var program: WorkoutProgram?

    init(exerciseId: String, exerciseName: String, sortIndex: Int, setCount: Int = 3, fixedReps: Int = 0) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sortIndex = sortIndex
        self.setCount = setCount
        self.fixedReps = fixedReps
    }
}

// MARK: - Schema versioning

enum ExercisSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WorkoutSession.self, ExerciseLog.self, SetLog.self,
         CardioSession.self, WorkoutProgram.self, ProgramExercise.self]
    }
}

enum ExercisMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ExercisSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
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
        let aliasMap = Dictionary(
            ExerciseDef.all.flatMap { def in def.aliases.map { ($0, def.name) } },
            uniquingKeysWith: { first, _ in first }
        )
        if !aliasMap.isEmpty {
            let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
            for log in logs {
                if let newName = aliasMap[log.name] { log.name = newName }
            }
            do { try context.save() } catch {
                    #if DEBUG
                    logger.error("context.save failed: \(error)")
                    #endif
                }
        }
        current = 2
    }

    if current < 3 {
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs where log.name == "Chest-Supported Row" {
            context.delete(log)
        }
        do { try context.save() } catch {
                #if DEBUG
                logger.error("context.save failed: \(error)")
                #endif
            }
    }

    if current < 4 {
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs where log.name == "Romanian Deadlift (RDL)" {
            log.name = "Romanian Deadlift"
        }
        do { try context.save() } catch {
                #if DEBUG
                logger.error("context.save failed: \(error)")
                #endif
            }
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
        do { try context.save() } catch {
                #if DEBUG
                logger.error("context.save failed: \(error)")
                #endif
            }
    }

    if current < 6 {
        let renames: [String: String] = [
            "Tricep Push Down Freewieghts": "Cable Triceps Pushdown"
        ]
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs {
            if let newName = renames[log.name] { log.name = newName }
        }
        do { try context.save() } catch {
                #if DEBUG
                logger.error("context.save failed: \(error)")
                #endif
            }
    }

    if current < 7 {
        let renames: [String: String] = [
            "Lat Pull Down (Straight Back)": "Lat Pulldown (Straight Back)",
            "Lat Pull Down (Leaning Back)": "Lat Pulldown (Leaning Back)",
            "Close-Grip Lat Pull Down": "Close-Grip Lat Pulldown",
            "Underhand Lat Pull Down": "Underhand Lat Pulldown",
            "Straight-Arm Pull Down (Rope Attachment)": "Straight-Arm Pulldown (Rope Attachment)",
            "Straight-Arm Pull Down (Bar Attachment)": "Straight-Arm Pulldown (Bar Attachment)",
            "Push Ups": "Push-Ups",
            "Incline Pushups": "Incline Push-Ups",
            "Decline Pushups": "Decline Push-Ups",
            "Wall Pushup": "Wall Push-Up",
            "Perfect Push Up": "Perfect Push-Up",
            "Pike Push Ups": "Pike Push-Ups",
            "Side To Side Push Ups": "Side-To-Side Push-Ups",
            "Benchpress Dumbbells": "Dumbbell Bench Press",
            "Bentover Dumbbell Rows": "Bent-Over Dumbbell Rows",
            "Pendelay Rows": "Pendlay Rows",
            "Biceps Curl With Cable": "Biceps Curls With Cable",
            "Triceps Extensions On Cable": "Triceps Extension On Cable",
            "Triceps Extensions On Cable With Bar": "Triceps Extension On Cable With Bar",
            "Leg Presses (Wide)": "Leg Press (Wide)",
            "Leg Presses (Narrow)": "Leg Press (Narrow)",
            "Side Raise": "Side Raises"
        ]
        let logs = (try? context.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        for log in logs {
            if let newName = renames[log.name] { log.name = newName }
        }
        do { try context.save() } catch {
                #if DEBUG
                logger.error("context.save failed: \(error)")
                #endif
            }
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
    do { try context.save() } catch {
            #if DEBUG
            logger.error("context.save failed: \(error)")
            #endif
        }

    UserDefaults.standard.set(1, forKey: key)
}

// MARK: - Seeder: default programs

func seedDefaultProgramsIfNeeded(context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: "hasSeededPrograms") else { return }
    let existing = (try? context.fetch(FetchDescriptor<WorkoutProgram>())) ?? []
    guard existing.isEmpty else {
        UserDefaults.standard.set(true, forKey: "hasSeededPrograms")
        return
    }

    let defaults: [(name: String, color: String, constraint: String, exercises: [(id: String, name: String)])] = [
        ("Full Body", "paletteIntenseRed", "", [
            ("wger_squats",                   "Squats"),
            ("wger_bench_press",              "Bench Press"),
            ("wger_romanian_deadlift",        "Romanian Deadlift"),
            ("wger_bent_over_rowing",         "Bent Over Rowing"),
            ("wger_shoulder_press_dumbbells", "Shoulder Press, Dumbbells"),
            ("wger_pullups",                  "Pull-Ups")
        ]),
        ("Överkropp", "paletteOrange", "upper", [
            ("wger_bench_press",              "Bench Press"),
            ("wger_bent_over_rowing",         "Bent Over Rowing"),
            ("wger_shoulder_press_dumbbells", "Shoulder Press, Dumbbells"),
            ("wger_pullups",                  "Pull-Ups"),
            ("wger_lateral_raises",           "Lateral Raises")
        ]),
        ("Underkropp", "paletteYellow", "legs", [
            ("wger_squats",                 "Squats"),
            ("wger_romanian_deadlift",      "Romanian Deadlift"),
            ("wger_leg_presses_wide",       "Leg Presses (Wide)"),
            ("wger_leg_curls_laying",       "Leg Curls (Laying)"),
            ("wger_standing_calf_raises",   "Standing Calf Raises")
        ]),
        ("Push", "paletteLime", "push", [
            ("wger_bench_press",                          "Bench Press"),
            ("wger_incline_dumbbell_press",               "Incline Dumbbell Press"),
            ("wger_shoulder_press_dumbbells",             "Shoulder Press, Dumbbells"),
            ("wger_lateral_raises",                       "Lateral Raises"),
            ("wger_triceps_extensions_on_cable_with_bar", "Triceps Extensions On Cable With Bar")
        ]),
        ("Pull", "paletteGreen", "pull", [
            ("wger_deadlifts",                  "Deadlifts"),
            ("wger_pullups",                    "Pull-Ups"),
            ("wger_rowing_seated",              "Rowing, Seated"),
            ("wger_rear_delt_raises",           "Rear Delt Raises"),
            ("wger_biceps_curls_with_dumbbell", "Biceps Curls With Dumbbell")
        ]),
        ("Legs", "paletteTeal", "legs", [
            ("wger_squats",             "Squats"),
            ("wger_romanian_deadlift",  "Romanian Deadlift"),
            ("wger_leg_presses_wide",   "Leg Presses (Wide)"),
            ("wger_leg_extension",      "Leg Extension"),
            ("wger_leg_curls_laying",   "Leg Curls (Laying)")
        ]),
        ("Bodyweight", "paletteCyan", "bodyweight", [
            ("wger_body_squats",         "Body Squats"),
            ("wger_push_ups",            "Push Ups"),
            ("wger_bodyweight_lunges",   "Bodyweight Lunges"),
            ("wger_superman",            "Superman"),
            ("wger_plank",               "Plank")
        ])
    ]

    var seededMap: [String: String] = [:]
    for (i, def) in defaults.enumerated() {
        let program = WorkoutProgram(name: def.name, colorName: def.color, sortIndex: i, programConstraint: def.constraint)
        program.isOnTrainingPage = false
        context.insert(program)
        seededMap[program.id.uuidString] = def.name
        for (j, ex) in def.exercises.enumerated() {
            let pe = ProgramExercise(exerciseId: ex.id, exerciseName: ex.name, sortIndex: j)
            pe.program = program
            context.insert(pe)
        }
    }
    do { try context.save() } catch {
            #if DEBUG
            logger.error("context.save failed: \(error)")
            #endif
        }
    if let data = try? JSONEncoder().encode(seededMap) {
        UserDefaults.standard.set(data, forKey: "seededProgramMap")
    }
    UserDefaults.standard.set(true, forKey: "hasSeededPrograms")
}

struct DefaultProgramDef {
    let name: String
    let color: String
    let constraint: String
    let exercises: [(id: String, name: String, setCount: Int)]
}

let allDefaultProgramDefs: [DefaultProgramDef] = [
    DefaultProgramDef(name: "Full Body", color: "paletteIntenseRed", constraint: "", exercises: [
        ("wger_squats",                   "Squats",                          3),
        ("wger_bench_press",              "Bench Press",                     3),
        ("wger_romanian_deadlift",        "Romanian Deadlift",               3),
        ("wger_bent_over_rowing",         "Bent Over Rowing",                3),
        ("wger_shoulder_press_dumbbells", "Shoulder Press, Dumbbells",       3),
        ("wger_pullups",                  "Pull-Ups",                        3)
    ]),
    DefaultProgramDef(name: "Överkropp", color: "paletteOrange", constraint: "upper", exercises: [
        ("wger_bench_press",              "Bench Press",                     3),
        ("wger_bent_over_rowing",         "Bent Over Rowing",                3),
        ("wger_shoulder_press_dumbbells", "Shoulder Press, Dumbbells",       3),
        ("wger_pullups",                  "Pull-Ups",                        3),
        ("wger_lateral_raises",           "Lateral Raises",                  3)
    ]),
    DefaultProgramDef(name: "Underkropp", color: "paletteYellow", constraint: "legs", exercises: [
        ("wger_squats",                 "Squats",                            3),
        ("wger_romanian_deadlift",      "Romanian Deadlift",                 3),
        ("wger_leg_presses_wide",       "Leg Presses (Wide)",                3),
        ("wger_leg_curls_laying",       "Leg Curls (Laying)",                3),
        ("wger_standing_calf_raises",   "Standing Calf Raises",              3)
    ]),
    DefaultProgramDef(name: "Push", color: "paletteLime", constraint: "push", exercises: [
        ("wger_bench_press",                          "Bench Press",                             3),
        ("wger_incline_dumbbell_press",               "Incline Dumbbell Press",                  3),
        ("wger_shoulder_press_dumbbells",             "Shoulder Press, Dumbbells",               3),
        ("wger_lateral_raises",                       "Lateral Raises",                          3),
        ("wger_triceps_extensions_on_cable_with_bar", "Triceps Extensions On Cable With Bar",    3)
    ]),
    DefaultProgramDef(name: "Pull", color: "paletteGreen", constraint: "pull", exercises: [
        ("wger_deadlifts",                  "Deadlifts",                     3),
        ("wger_pullups",                    "Pull-Ups",                      3),
        ("wger_rowing_seated",              "Rowing, Seated",                3),
        ("wger_rear_delt_raises",           "Rear Delt Raises",              3),
        ("wger_biceps_curls_with_dumbbell", "Biceps Curls With Dumbbell",   3)
    ]),
    DefaultProgramDef(name: "Legs", color: "paletteTeal", constraint: "legs", exercises: [
        ("wger_squats",             "Squats",                   3),
        ("wger_romanian_deadlift",  "Romanian Deadlift",        3),
        ("wger_leg_presses_wide",   "Leg Presses (Wide)",       3),
        ("wger_leg_extension",      "Leg Extension",            3),
        ("wger_leg_curls_laying",   "Leg Curls (Laying)",       3)
    ]),
    DefaultProgramDef(name: "Bodyweight", color: "paletteCyan", constraint: "bodyweight", exercises: [
        ("wger_body_squats",         "Body Squats",          3),
        ("wger_push_ups",            "Push Ups",             3),
        ("wger_bodyweight_lunges",   "Bodyweight Lunges",    3),
        ("wger_superman",            "Superman",             3),
        ("wger_plank",               "Plank",                3)
    ])
]

func backfillSeededProgramMapIfNeeded(context: ModelContext) {
    guard UserDefaults.standard.data(forKey: "seededProgramMap") == nil else { return }
    let programs = (try? context.fetch(FetchDescriptor<WorkoutProgram>())) ?? []
    var map: [String: String] = [:]
    for def in allDefaultProgramDefs {
        if let match = programs.first(where: { $0.name == def.name }) {
            map[match.id.uuidString] = def.name
        }
    }
    if let data = try? JSONEncoder().encode(map) {
        UserDefaults.standard.set(data, forKey: "seededProgramMap")
    }
}

func defaultProgramDef(for programId: UUID) -> DefaultProgramDef? {
    guard let data = UserDefaults.standard.data(forKey: "seededProgramMap"),
          let map = try? JSONDecoder().decode([String: String].self, from: data),
          let defaultName = map[programId.uuidString] else { return nil }
    return allDefaultProgramDefs.first { $0.name == defaultName }
}
