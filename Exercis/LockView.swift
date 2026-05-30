import SwiftUI

#Preview {
    LockView(auth: AuthManager())
}

struct LockView: View {
    @ObservedObject var auth: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("EXERCIS")
                .font(.jost(.black, size: 38))
                .kerning(6)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                Button("LOGGA IN") {
                    auth.authenticate()
                }
                .buttonStyle(FilledButtonStyle(accent: Color.homeAccent))

                Color.clear.frame(height: 50)
                Color.clear.frame(height: 50)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            Text(" ")
                .font(.jost(.regular, size: 12))
                .kerning(1)
                .padding(.top, 24)
                .opacity(0)

            Spacer()
        }
        .onAppear {
            auth.authenticate()
        }
    }
}
