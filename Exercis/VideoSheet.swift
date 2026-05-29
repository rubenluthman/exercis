import SwiftUI
import SafariServices

struct VideoSheet: View {
    let def: ExerciseDef

    var body: some View {
        if let url = URL(string: def.videoURL) {
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
