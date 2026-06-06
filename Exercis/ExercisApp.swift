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

        if let bold = UIFont(name: "Jost-Bold", size: 17),
           let regular = UIFont(name: "Jost-Regular", size: 17) {
            UINavigationBar.appearance().titleTextAttributes = [.font: bold]
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: bold]
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: regular], for: .normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: regular], for: .highlighted)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(try! ModelContainer(
            for: Schema(ExercisSchemaV1.models),
            migrationPlan: ExercisMigrationPlan.self
        ))
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
                TrainingView()
            }
            .tabItem {
                Label("TRAINING", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                HistoryView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("HISTORY", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                ProfileView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("PROFILE", systemImage: "person.fill")
            }

            NavigationStack {
                SettingsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("SETTINGS", systemImage: "gearshape.fill")
            }
        }
        .minimizeTabBarOnScroll()
        .onAppear {
            migrateExerciseNames(context: context)
            migrateCardioTypes(context: context)
            seedDefaultProgramsIfNeeded(context: context)
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
    }
}

private extension View {
    @ViewBuilder func minimizeTabBarOnScroll() -> some View {
        if #available(iOS 26, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
