import SwiftUI
import Foundation

// MARK: - GIF Source

enum GifSource: String, Codable {
    case hasaneyldrm
    case exercisedb
    case needsSource
    case none
}

// MARK: - ExerciseDef

struct ExerciseDef: Identifiable {
    let id: String
    let name: String
    let movement: String?
    let mechanic: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    let contraindications: [String]
    let repRangeMin: Int
    let repRangeMax: Int
    let setRangeMin: Int
    let setRangeMax: Int
    let gifFile: String?
    let gifSource: GifSource
    var aliases: [String] = []
    var description: String? = nil

    var displayName: String { name }
    var shortName: String? { nil }
    var repRange: String { "\(repRangeMin)–\(repRangeMax) REPS" }
    var videoURL: String { "" }

    var hasGif: Bool {
        gifSource == .hasaneyldrm || gifSource == .exercisedb
    }

    var gifBundleURL: URL? {
        guard let file = gifFile else { return nil }
        return Bundle.main.url(forResource: file, withExtension: nil, subdirectory: "GIFs")
            ?? Bundle.main.url(forResource: file, withExtension: nil, subdirectory: "Resources/GIFs")
            ?? Bundle.main.url(forResource: file, withExtension: nil)
    }
}

// MARK: - Static interface (backward compat)

extension ExerciseDef {
    static var all: [ExerciseDef] { ExerciseLibrary.shared.exercises }
    static var retired: [ExerciseDef] { [] }

    static func find(name: String) -> ExerciseDef? {
        ExerciseLibrary.shared.find(name: name)
    }

    static func find(id: String) -> ExerciseDef? {
        ExerciseLibrary.shared.find(id: id)
    }

    static let migrationVersion = 5
}

// MARK: - JSON Codable

private struct ExerciseDefJSON: Codable {
    let id: String
    let name: String
    let movement: String?
    let mechanic: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    let contraindications: [String]
    let status: String
    let repRange: RangeJSON
    let setRange: RangeJSON
    let gifFile: String?
    let gifSource: String?
    let aliases: [String]?
    let description: String?

    struct RangeJSON: Codable {
        let min: Int
        let max: Int
    }
}

// MARK: - Body Limitation

enum BodyLimitation: String, CaseIterable {
    case knee     = "knee"
    case shoulder = "shoulder"
    case back     = "back"
    case elbow    = "elbow"
    case wrist    = "wrist"
    case hip      = "hip"

    var displayName: String {
        switch self {
        case .knee:     return "KNÄ"
        case .shoulder: return "AXEL"
        case .back:     return "RYGG"
        case .elbow:    return "ARMBÅGE"
        case .wrist:    return "HANDLED"
        case .hip:      return "HÖFT"
        }
    }

    var contraindications: [String] {
        switch self {
        case .knee:     return ["knee_compression", "knee_flexion_loaded"]
        case .shoulder: return ["shoulder_compression", "shoulder_impingement", "shoulder_instability"]
        case .back:     return ["lumbar_compression", "lumbar_extension", "lumbar_flexion", "lumbar_rotation"]
        case .elbow:    return ["elbow_extension_loaded", "elbow_flexion_loaded", "elbow_medial"]
        case .wrist:    return ["wrist_extension", "wrist_grip"]
        case .hip:      return ["hip_flexion_loaded"]
        }
    }
}

// MARK: - Program Constraint

enum ProgramConstraint: String, CaseIterable {
    case none       = ""
    case push       = "push"
    case pull       = "pull"
    case legs       = "legs"
    case upper      = "upper"
    case bodyweight = "bodyweight"

    var displayName: String {
        switch self {
        case .none:       return "INGEN"
        case .push:       return "PUSH"
        case .pull:       return "PULL"
        case .legs:       return "BEN"
        case .upper:      return "ÖVERKROPP"
        case .bodyweight: return "KROPPSVIKT"
        }
    }

    func matches(_ def: ExerciseDef) -> Bool {
        switch self {
        case .none:   return true
        case .push:   return def.movement == "push"
        case .pull:   return def.movement == "pull"
        case .legs:
            let legMuscles = Set(["quadriceps", "hamstrings", "glutes", "calves"])
            return def.primaryMuscles.contains { legMuscles.contains($0) }
        case .upper:
            let legMuscles = Set(["quadriceps", "hamstrings", "glutes", "calves"])
            return def.primaryMuscles.allSatisfy { !legMuscles.contains($0) }
        case .bodyweight:
            let bwEquipment = Set(["bodyweight", "pull_up_bar", "dip_bar"])
            return def.equipment.allSatisfy { bwEquipment.contains($0) }
        }
    }
}

// MARK: - Muscle Group

enum MuscleGroup: String, CaseIterable {
    case chest     = "chest"
    case back      = "back"
    case shoulders = "shoulders"
    case legs      = "legs"
    case arms      = "arms"
    case core      = "core"

    var displayName: String {
        switch self {
        case .chest:     return "BRÖST"
        case .back:      return "RYGG"
        case .shoulders: return "AXLAR"
        case .legs:      return "BEN"
        case .arms:      return "ARMAR"
        case .core:      return "CORE"
        }
    }

    var muscles: [String] {
        switch self {
        case .chest:     return ["chest"]
        case .back:      return ["latissimus_dorsi", "trapezius", "rear_deltoid", "erector_spinae"]
        case .shoulders: return ["front_deltoid", "side_deltoid", "rear_deltoid"]
        case .legs:      return ["quadriceps", "hamstrings", "glutes", "calves"]
        case .arms:      return ["biceps", "triceps", "forearms"]
        case .core:      return ["abs", "obliques"]
        }
    }

    func matches(_ def: ExerciseDef) -> Bool {
        def.primaryMuscles.contains { muscles.contains($0) }
    }
}

// MARK: - ExerciseLibrary

final class ExerciseLibrary {
    static let shared = ExerciseLibrary()
    private(set) var exercises: [ExerciseDef] = []

    private init() { load() }

    private func load() {
        guard
            let url = Bundle.main.url(forResource: "exercises_def", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let raw = try? JSONDecoder().decode([ExerciseDefJSON].self, from: data)
        else { return }

        exercises = raw
            .filter { $0.status == "include" }
            .map { json in
                ExerciseDef(
                    id: json.id,
                    name: json.name,
                    movement: json.movement,
                    mechanic: json.mechanic,
                    primaryMuscles: json.primaryMuscles,
                    secondaryMuscles: json.secondaryMuscles,
                    equipment: json.equipment,
                    contraindications: json.contraindications,
                    repRangeMin: json.repRange.min,
                    repRangeMax: json.repRange.max,
                    setRangeMin: json.setRange.min,
                    setRangeMax: json.setRange.max,
                    gifFile: json.gifFile,
                    gifSource: GifSource(rawValue: json.gifSource ?? "none") ?? .none,
                    aliases: json.aliases ?? [],
                    description: json.description
                )
            }
    }

    func find(name: String) -> ExerciseDef? {
        exercises.first { $0.name == name }
    }

    func find(id: String) -> ExerciseDef? {
        exercises.first { $0.id == id }
    }
}
