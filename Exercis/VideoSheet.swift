import SwiftUI
import SafariServices

struct VideoSheet: View {
    let def: ExerciseDef

    var body: some View {
        SafariView(url: URL(string: def.videoURL)!)
            .ignoresSafeArea()
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
