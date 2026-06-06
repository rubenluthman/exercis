import SwiftUI
import UIKit

// MARK: - Colors

extension Color {
    // Structural accent colors — map to palette entries
    static let homeAccent    = Color("paletteIntenseRed")  // light #B73B3F / dark #F97775
    static let workoutAccent = Color("paletteGreen")       // light #23821F / dark #63BD5C
    static let historyAccent = Color("paletteLightBlue")   // light #0078B8 / dark #00B3F7
    static let appBackground = Color(.systemBackground)
    static let appDivider    = Color(.separator)

    static let programPalette: [Color] = ProgramColor.allCases.map(\.color)
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

    var color: Color { Color(rawValue) }

    var darkHex: String {
        switch self {
        case .intenseRed: return "F97775"
        case .orange:     return "F18435"
        case .yellow:     return "D59800"
        case .lime:       return "A7AE00"
        case .green:      return "63BD5C"
        case .teal:       return "00C49A"
        case .cyan:       return "00C0D0"
        case .lightBlue:  return "00B3F7"
        case .darkBlue:   return "6DA2FF"
        case .purple:     return "A98FFF"
        case .magenta:    return "D37FDF"
        case .pink:       return "EE76AE"
        }
    }
}

// MARK: - Typography

extension Font {
    static func jost(_ weight: Font.Weight, size: CGFloat) -> Font {
        let name: String
        switch weight {
        case .black:    name = "Jost-Black"
        case .bold:     name = "Jost-Bold"
        case .semibold: name = "Jost-SemiBold"
        case .medium:   name = "Jost-Medium"
        default:        name = "Jost-Regular"
        }
        let style: TextStyle
        switch size {
        case ..<12:  style = .caption2
        case ..<15:  style = .caption
        case ..<18:  style = .body
        case ..<24:  style = .headline
        case ..<32:  style = .title2
        default:     style = .largeTitle
        }
        return .custom(name, size: size, relativeTo: style)
    }
}

// MARK: - Button Styles

struct FilledButtonStyle: ButtonStyle {
    let accent: Color
    var fontSize: CGFloat = 15
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jost(.bold, size: fontSize))
            .kerning(1.8)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(accent.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct OutlineButtonStyle: ButtonStyle {
    let accent: Color
    var fontSize: CGFloat = 15
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jost(.bold, size: fontSize))
            .kerning(1.8)
            .foregroundColor(accent.opacity(configuration.isPressed ? 0.65 : 1))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(accent.opacity(configuration.isPressed ? 0.65 : 1), lineWidth: 1)
            )
    }
}

// MARK: - iOS 26 glass button variant — valt adaptivt av primaryButtonStyle (glass på 26+, fylld rektangel på äldre)
@available(iOS 26, *)
struct GlassFilledButtonStyle: ButtonStyle {
    let accent: Color
    var fontSize: CGFloat = 15
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jost(.bold, size: fontSize))
            .kerning(1.8)
            .foregroundStyle(accent)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .glassEffect(.regular.tint(accent.opacity(0.25)), in: .rect(cornerRadius: 4))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension View {
    func primaryButtonStyle(accent: Color, fontSize: CGFloat = 15) -> some View {
        Group {
            if #available(iOS 26, *) {
                self.buttonStyle(GlassFilledButtonStyle(accent: accent, fontSize: fontSize))
            } else {
                self.buttonStyle(FilledButtonStyle(accent: accent, fontSize: fontSize))
            }
        }
    }
}

// MARK: - Shared UI

struct ThinDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: 0.5)
    }
}

// MARK: - Navigation

private struct PopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            vc.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

extension View {
    func enableSwipeBack() -> some View {
        background(PopGestureEnabler())
    }

    func softScrollEdge() -> some View {
        self.mask(
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 20)
                Color.black
            }
        )
    }
}

// MARK: - Haptics

enum Haptics {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Epley e1RM

func epleyE1RM(weight: Double, reps: Int) -> Double {
    guard reps > 0, weight > 0 else { return 0 }
    return weight * (1 + Double(reps) / 30)
}

func estimatedCalories(met: Double, bodyMass: Double, seconds: Double) -> Double {
    met * bodyMass * (seconds / 3600)
}

// MARK: - Streak

func computeCurrentStreak(days: Set<Date>) -> Int {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    var cursor = days.contains(today) ? today : cal.date(byAdding: .day, value: -1, to: today)!
    var count = 0
    while days.contains(cursor) {
        count += 1
        cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
    }
    return count
}

func computeBestStreak(days: Set<Date>) -> Int {
    guard !days.isEmpty else { return 0 }
    let cal = Calendar.current
    var best = 0
    var current = 0
    var cursor = days.min()!
    let last = days.max()!
    while cursor <= last {
        if days.contains(cursor) {
            current += 1
            best = max(best, current)
        } else {
            current = 0
        }
        cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
    }
    return best
}

// MARK: - Progression suggestion

func progressionSuggestion(prevMax: Double, shouldIncrease: Bool, bestSetReps: Int) -> (weight: Double, reps: Int) {
    let targetWeight = shouldIncrease ? prevMax + 2.5 : prevMax
    return (targetWeight, bestSetReps)
}

// MARK: - CSV export

// RFC 4180: kvotera fält som innehåller komma, citattecken eller radbrytning; dubblera inre citattecken
func csvField(_ value: String) -> String {
    guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
    return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
}

func strengthCSV(_ sessions: [WorkoutSession]) -> String {
    var rows = ["datum,program,övning,set,kg,reps,e1RM"]
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withFullDate]
    for session in sessions {
        let date = fmt.string(from: session.date)
        let program = csvField(session.programName ?? "")
        for log in session.exerciseLogs.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let exercise = csvField(log.name)
            for set in log.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                let e1rm = set.reps > 0 ? set.weight * (1 + Double(set.reps) / 30) : set.weight
                rows.append("\(date),\(program),\(exercise),\(set.setNumber),\(formatWeight(set.weight)),\(set.reps),\(String(format: "%.1f", e1rm))")
            }
        }
    }
    return rows.joined(separator: "\n")
}

func cardioCSV(_ sessions: [CardioSession]) -> String {
    var rows = ["datum,typ,minuter,km,ansträngning"]
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withFullDate]
    for session in sessions {
        let date = fmt.string(from: session.date)
        let type_ = csvField(CardioType(rawValue: session.cardioType)?.displayName ?? session.cardioType)
        let km = session.distanceKm.map { formatWeight($0) } ?? ""
        let effort = session.effortScore.map { "\($0)" } ?? ""
        rows.append("\(date),\(type_),\(formatWeight(session.durationMinutes)),\(km),\(effort)")
    }
    return rows.joined(separator: "\n")
}

// MARK: - Weight Formatting

func formatWeight(_ value: Double) -> String {
    let f = NumberFormatter()
    f.locale = Locale.current
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 2
    return f.string(from: NSNumber(value: value)) ?? "\(value)"
}

func parseWeight(_ text: String) -> Double? {
    let normalized = text.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
}

// MARK: - Unit-aware display (kg/lbs, km/mi)

func displayWeight(_ kg: Double, imperial: Bool) -> String {
    formatWeight(imperial ? kg * 2.20462 : kg)
}

func displayDistance(_ km: Double, imperial: Bool) -> String {
    formatWeight(imperial ? km * 0.621371 : km)
}

func parseWeightInput(_ text: String, imperial: Bool) -> Double? {
    guard let value = parseWeight(text) else { return nil }
    return imperial ? value / 2.20462 : value
}

func parseDistanceInput(_ text: String, imperial: Bool) -> Double? {
    guard let value = parseWeight(text) else { return nil }
    return imperial ? value / 0.621371 : value
}

func weightLabel(_ imperial: Bool) -> String { imperial ? "LBS" : "KG" }
func distanceLabel(_ imperial: Bool) -> String { imperial ? "MI" : "KM" }
