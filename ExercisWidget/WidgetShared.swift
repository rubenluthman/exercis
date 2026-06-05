import Foundation
import WidgetKit
import SwiftUI

// Shared types between app target and widget target.
// The app writes via WidgetDataStore; the widget reads the same UserDefaults suite.

struct WidgetSnapshot: Codable {
    var streak: Int
    var lastSessionDate: Date?
    var lastSessionProgramName: String?
    var lastSessionExerciseCount: Int
    var nextProgramName: String?
    var nextProgramColorName: String?
}

struct WidgetDataStore {
    static let suiteName = "group.rubenluthman.Exercis"
    private static let key = "widgetSnapshot"

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return WidgetSnapshot(streak: 0, lastSessionExerciseCount: 0)
        }
        return snapshot
    }
}

enum ProgramColor: String, CaseIterable {
    case intenseRed = "paletteIntenseRed"
    case orange     = "paletteOrange"
    case yellow     = "paletteYellow"
    case lime       = "paletteLime"
    case green      = "paletteGreen"
    case teal       = "paletteTeal"
    case cyan       = "paletteCyan"
    case lightBlue  = "paletteLightBlue"
    case darkBlue   = "paletteDarkBlue"
    case purple     = "palettePurple"
    case magenta    = "paletteMagenta"
    case pink       = "palettePink"

    var color: Color {
        switch self {
        case .intenseRed: return Color(red: 0.97, green: 0.47, blue: 0.46)
        case .orange:     return Color(red: 0.95, green: 0.52, blue: 0.21)
        case .yellow:     return Color(red: 0.84, green: 0.60, blue: 0.00)
        case .lime:       return Color(red: 0.65, green: 0.68, blue: 0.00)
        case .green:      return Color(red: 0.39, green: 0.74, blue: 0.36)
        case .teal:       return Color(red: 0.00, green: 0.77, blue: 0.60)
        case .cyan:       return Color(red: 0.00, green: 0.75, blue: 0.82)
        case .lightBlue:  return Color(red: 0.00, green: 0.70, blue: 0.97)
        case .darkBlue:   return Color(red: 0.43, green: 0.64, blue: 1.00)
        case .purple:     return Color(red: 0.66, green: 0.56, blue: 1.00)
        case .magenta:    return Color(red: 0.83, green: 0.50, blue: 0.87)
        case .pink:       return Color(red: 0.93, green: 0.46, blue: 0.68)
        }
    }
}
