import ActivityKit
import Foundation

struct ExercisActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var exerciseName: String
        var setNumber: Int
        var totalSets: Int
        var exerciseIndex: Int
        var totalExercises: Int
    }
    var programName: String
    var accentHex: String
}
