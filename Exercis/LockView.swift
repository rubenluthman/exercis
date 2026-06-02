import SwiftUI

#Preview {
    LockView(auth: AuthManager())
}

struct LockView: View {
    @ObservedObject var auth: AuthManager
    @State private var authFailed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("EXERCIS")
                .font(.jost(.black, size: 38))
                .kerning(6)
                .foregroundColor(.primary)

            Spacer()

            Button {
                if authFailed {
                    authFailed = false
                    auth.authenticate()
                }
            } label: {
                Image(systemName: "faceid")
                    .font(.jost(.regular, size: 40))
                    .foregroundStyle(authFailed ? Color(.secondaryLabel) : .clear)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Logga in")
            .disabled(!authFailed)
            .padding(.bottom, 60)
        }
        .onAppear {
            auth.authenticate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .authFailed)) { _ in
            authFailed = true
        }
    }
}
