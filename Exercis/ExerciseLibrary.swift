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

    struct RangeJSON: Codable {
        let min: Int
        let max: Int
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
                    aliases: json.aliases ?? []
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
