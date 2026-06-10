import SwiftUI
import WebKit

struct GifSheet: View {
    let def: ExerciseDef
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let url = def.gifBundleURL {
                    if reduceMotion {
                        staticFrameView(url: url)
                            .accessibilityLabel("Animation showing \(def.displayName)")
                    } else {
                        GifWebView(url: url)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Animation showing \(def.displayName)")
                            .accessibilityAddTraits(.isImage)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text(def.displayName.uppercased())
                        .font(.jost(.bold, size: 17))
                        .kerning(2)
                        .foregroundStyle(.primary)
                        .padding(.top, 20)

                    if let description = def.description {
                        Text(description)
                            .font(.jost(.regular, size: 14))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ThinDivider()

                    if !def.primaryMuscles.isEmpty {
                        muscleSection(label: "PRIMARY MUSCLES", muscles: def.primaryMuscles)
                    }
                    if !def.secondaryMuscles.isEmpty {
                        muscleSection(label: "SECONDARY MUSCLES", muscles: def.secondaryMuscles)
                    }
                    if let movement = def.movement {
                        infoRow(label: "MOVEMENT", value: movement.capitalized)
                    }
                    if let mechanic = def.mechanic {
                        infoRow(label: "MECHANIC", value: mechanic.capitalized)
                    }
                    if !def.equipment.isEmpty {
                        infoRow(label: "EQUIPMENT", value: def.equipment.map { $0.capitalized }.joined(separator: ", "))
                    }
                    if def.repRangeMin > 0 {
                        infoRow(label: "REP RANGE", value: "\(def.repRangeMin)–\(def.repRangeMax)")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func staticFrameView(url: URL) -> some View {
        Group {
            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func muscleSection(label: String, muscles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(label))
                .font(.jost(.medium, size: 12))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
            Text(muscles.map { $0.muscleDisplayName }.joined(separator: ", "))
                .font(.jost(.regular, size: 15))
                .foregroundStyle(.primary)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.jost(.medium, size: 12))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
            Text(value)
                .font(.jost(.regular, size: 15))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - WKWebView wrapper for GIF

struct GifWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let data = try? Data(contentsOf: url) else { return }
        let base64 = data.base64EncodedString()
        let html = """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: transparent; }
        img { width: 100%; height: auto; display: block; }
        </style>
        </head><body>
        <img src="data:image/gif;base64,\(base64)">
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
