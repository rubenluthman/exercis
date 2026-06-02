import SwiftUI
import SwiftData

@main
struct ExercisApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            "healthKitSyncEnabled":   true,
            "healthKitWeightEnabled": true,
            "lockEnabled":            true,
            "restTimerSeconds":       90
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [WorkoutSession.self, CardioSession.self, WorkoutProgram.self])
    }
}

// MARK: - RootView

struct RootView: View {
    @StateObject private var auth = AuthManager()
    @AppStorage("lockEnabled") private var lockEnabled = true
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        if lockEnabled && !auth.isAuthenticated {
            LockView(auth: auth)
        } else if !onboardingCompleted {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            NavigationStack {
                ProgramListView()
            }
            .tabItem {
                Label("Styrka", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                CardioView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Kondition", systemImage: "heart.fill")
            }

            NavigationStack {
                HistoryView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Historik", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                ProfileView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
        }
        .onAppear {
            migrateExerciseNames(context: context)
            migrateCardioTypes(context: context)
            seedDefaultProgramsIfNeeded(context: context)
        }
    }
}
