import Foundation
import Combine
import LocalAuthentication

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isAuthenticated = true
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Lås upp Exercis"
        ) { success, _ in
            DispatchQueue.main.async {
                if success { self.isAuthenticated = true }
            }
        }
    }
}
