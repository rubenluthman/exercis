#if canImport(ActivityKit)
import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<ExercisActivityAttributes>?

    func endAllZombies() {
        Task {
            for zombie in Activity<ExercisActivityAttributes>.activities {
                await zombie.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func start(programName: String, colorName: String, state: ExercisActivityAttributes.ContentState) {
        let attributes = ExercisActivityAttributes(
            programName: programName,
            accentHex: Self.hexForColorName(colorName)
        )
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }

    func update(state: ExercisActivityAttributes.ContentState) {
        Task { await activity?.update(.init(state: state, staleDate: nil)) }
    }

    func end() {
        Task { await activity?.end(nil, dismissalPolicy: .immediate) }
        activity = nil
    }

    private static func hexForColorName(_ name: String) -> String {
        ProgramColor(rawValue: name)?.darkHex ?? "F97775"
    }
}
#endif
