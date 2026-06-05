import Foundation
import WidgetKit

struct WidgetSnapshot: Codable {
    var streak: Int
    var lastSessionDate: Date?
    var lastSessionProgramName: String?
    var lastSessionExerciseCount: Int
    var nextProgramName: String?
    var nextProgramColorName: String?
}

struct WidgetDataStore {
    private static let suiteName = "group.rubenluthman.Exercis"
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
