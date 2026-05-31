import SwiftUI
import SwiftData

enum AppScreen: String, Hashable {
    case workout
    case cardio
    case history
}

@main
struct ExercisApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            "healthKitSyncEnabled":   true,
            "healthKitWeightEnabled": true,
            "lockEnabled":            true
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [WorkoutSession.self, CardioSession.self])
    }
}

struct RootView: View {
    @StateObject private var auth = AuthManager()
    @AppStorage("lockEnabled") private var lockEnabled = true

    var body: some View {
        if lockEnabled && !auth.isAuthenticated {
            LockView(auth: auth)
        } else {
            NavigationStack {
                HomeView()
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: AppScreen.self) { screen in
                        switch screen {
                        case .workout:
                            StrengthView()
                                .toolbar(.hidden, for: .navigationBar)
                                .enableSwipeBack()
                        case .cardio:
                            CardioView()
                                .toolbar(.hidden, for: .navigationBar)
                                .enableSwipeBack()
                        case .history:
                            HistoryView()
                                .toolbar(.hidden, for: .navigationBar)
                                .enableSwipeBack()
                        }
                    }
            }
        }
    }
}
