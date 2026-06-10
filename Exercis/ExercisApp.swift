import SwiftUI
import SwiftData

@main
struct ExercisApp: App {
    private let modelContainer: ModelContainer
    private let modelContainerFailedToLoad: Bool

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

        let schema = Schema(ExercisSchemaV1.models)
        if let container = try? ModelContainer(for: schema, migrationPlan: ExercisMigrationPlan.self) {
            modelContainer = container
            modelContainerFailedToLoad = false
        } else if let fallback = try? ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
            modelContainer = fallback
            modelContainerFailedToLoad = true
        } else {
            fatalError("Unable to create ModelContainer, even in-memory.")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(dataStoreUnavailable: modelContainerFailedToLoad)
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - RootView

struct RootView: View {
    let dataStoreUnavailable: Bool

    @StateObject private var auth = AuthManager()
    @AppStorage("lockEnabled") private var lockEnabled = true
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @State private var showingDataStoreWarning = false

    var body: some View {
        Group {
            if lockEnabled && !auth.isAuthenticated {
                LockView(auth: auth)
            } else if !onboardingCompleted {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .onAppear { showingDataStoreWarning = dataStoreUnavailable }
        .alert("Couldn't Load Saved Data", isPresented: $showingDataStoreWarning) {
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Exercis couldn't open its database and is running with a temporary, in-memory store. Your sessions and programs won't be saved this time — try restarting the app.")
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
            backfillSeededProgramMapIfNeeded(context: context)
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
    }
}

private extension View {
    @ViewBuilder func minimizeTabBarOnScroll() -> some View {
#if swift(>=6.2)
        if #available(iOS 26, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
#else
        self
#endif
    }
}
