import SwiftUI
import WebKit

struct GifSheet: View {
    let def: ExerciseDef
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(def.displayName.uppercased())
                    .font(.jost(.bold, size: 13))
                    .kerning(2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { showInfo.toggle() }
                } label: {
                    Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.historyAccent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Övningsinformation")
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)

            ThinDivider()

            if showInfo {
                infoView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                gifView
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
    }

    // MARK: - GIF

    @ViewBuilder
    private var gifView: some View {
        if let url = def.gifBundleURL {
            if reduceMotion {
                staticFrameView(url: url)
            } else {
                GifWebView(url: url)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(16)
            }
        }
    }

    private func staticFrameView(url: URL) -> some View {
        Group {
            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            } else {
                Rectangle()
                    .fill(Color(.secondarySystemFill))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(16)
            }
        }
    }

    // MARK: - Info

    private var infoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
            .padding(.vertical, 20)
        }
    }

    private func muscleSection(label: String, muscles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
            Text(muscles.map { $0.capitalized }.joined(separator: ", "))
                .font(.jost(.regular, size: 15))
                .foregroundStyle(.primary)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.jost(.medium, size: 10))
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
        let html = """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; }
        img { max-width: 100%; max-height: 100vh; object-fit: contain; }
        </style>
        </head><body>
        <img src="\(url.lastPathComponent)">
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }
}
