#if canImport(ActivityKit)
import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<ExercisActivityAttributes>?

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
        switch name {
        case "paletteIntenseRed": return "F97775"
        case "paletteOrange":     return "F18435"
        case "paletteYellow":     return "D59800"
        case "paletteLime":       return "A7AE00"
        case "paletteGreen":      return "63BD5C"
        case "paletteTeal":       return "00C49A"
        case "paletteCyan":       return "00C0D0"
        case "paletteLightBlue":  return "00B3F7"
        case "paletteDarkBlue":   return "6DA2FF"
        case "palettePurple":     return "A98FFF"
        case "paletteMagenta":    return "D37FDF"
        case "palettePink":       return "EE76AE"
        default:                  return "F97775"
        }
    }
}
#endif
