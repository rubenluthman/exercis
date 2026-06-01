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

    // Program color palette (OKLCH L=0.5325 C=0.160, 12 hues × 30°)
    // Light/dark variants defined in Assets.xcassets — automatic dark mode
    static let paletteIntenseRed = Color("paletteIntenseRed") // H=22.4°
    static let paletteOrange     = Color("paletteOrange")     // H=52.4°
    static let paletteYellow     = Color("paletteYellow")     // H=82.4°
    static let paletteLime       = Color("paletteLime")       // H=112.4°
    static let paletteGreen      = Color("paletteGreen")      // H=142.4°
    static let paletteTeal       = Color("paletteTeal")       // H=172.4°
    static let paletteCyan       = Color("paletteCyan")       // H=202.4°
    static let paletteLightBlue  = Color("paletteLightBlue")  // H=232.4°
    static let paletteDarkBlue   = Color("paletteDarkBlue")   // H=262.4°
    static let palettePurple     = Color("palettePurple")     // H=292.4°
    static let paletteMagenta    = Color("paletteMagenta")    // H=322.4°
    static let palettePink       = Color("palettePink")       // H=352.4°

    static let programPalette: [Color] = [
        .paletteIntenseRed, .paletteOrange, .paletteYellow, .paletteLime,
        .paletteGreen, .paletteTeal, .paletteCyan, .paletteLightBlue,
        .paletteDarkBlue, .palettePurple, .paletteMagenta, .palettePink
    ]
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
