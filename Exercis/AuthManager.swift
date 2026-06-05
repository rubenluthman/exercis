import Foundation
import Combine
import LocalAuthentication

extension Notification.Name {
    static let authFailed = Notification.Name("authFailed")
}

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
            localizedReason: String(localized: "Unlock Exercis")
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                } else {
                    NotificationCenter.default.post(name: .authFailed, object: nil)
                }
            }
        }
    }
}
