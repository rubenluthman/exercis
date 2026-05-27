import SwiftUI
import UIKit

// MARK: - Colors

extension Color {
    static let homeAccent    = Color(hex: "#B04848")
    static let workoutAccent = Color(hex: "#4A8050")
    static let historyAccent = Color(hex: "#4878B0")
    static let appBackground = Color.white
    static let appDivider    = Color(white: 0.82)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
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
        return .custom(name, size: size)
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
