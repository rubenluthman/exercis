import SwiftUI
import SwiftData

// MARK: - Preview helpers

@MainActor
private func makeContainer() -> ModelContainer {
    let container = try! ModelContainer(
        for: WorkoutSession.self, CardioSession.self, WorkoutProgram.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext

    let p1 = WorkoutProgram(name: "Full Body", colorName: "paletteIntenseRed", sortIndex: 0)
    p1.isOnTrainingPage = true
    let p2 = WorkoutProgram(name: "Överkropp", colorName: "paletteLightBlue", sortIndex: 1)
    p2.isOnTrainingPage = true
    ctx.insert(p1)
    ctx.insert(p2)

    let ex1 = ProgramExercise(exerciseId: "wger_squats", exerciseName: "Squats", sortIndex: 0, setCount: 3)
    ex1.program = p1
    let ex2 = ProgramExercise(exerciseId: "wger_romanian_deadlift", exerciseName: "Romanian Deadlift", sortIndex: 1, setCount: 3)
    ex2.program = p1
    ctx.insert(ex1)
    ctx.insert(ex2)

    let session = WorkoutSession()
    session.programId = p1.id
    session.programName = "Full Body"
    let log = ExerciseLog(name: "Squats", orderIndex: 0)
    log.session = session
    let set1 = SetLog(setNumber: 1, weight: 80, reps: 8)
    set1.exerciseLog = log
    ctx.insert(session)
    ctx.insert(log)
    ctx.insert(set1)

    let cardio = CardioSession(date: Date(), durationMinutes: 45, cardioType: "VANDRING", distanceKm: 6.6)
    cardio.effortScore = 7
    ctx.insert(cardio)

    try? ctx.save()
    return container
}

// MARK: - TrainingView

#Preview("TrainingView") {
    NavigationStack {
        TrainingView()
    }
    .modelContainer(makeContainer())
    .onAppear {
        UserDefaults.standard.set("VANDRING,CROSSTRAINER", forKey: "selectedCardioTypes")
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
}

// MARK: - CardioView

#Preview("CardioView — Vandring") {
    NavigationStack {
        CardioView(type: .hiking)
    }
    .modelContainer(makeContainer())
}

#Preview("CardioView — Crosstrainer") {
    NavigationStack {
        CardioView(type: .crosstrainer)
    }
    .modelContainer(makeContainer())
}

// MARK: - SettingsView

#Preview("SettingsView") {
    NavigationStack {
        SettingsView()
            .toolbar(.hidden, for: .navigationBar)
    }
    .modelContainer(makeContainer())
}

// MARK: - ProfileView

#Preview("ProfileView — med namn") {
    NavigationStack {
        ProfileView()
            .toolbar(.hidden, for: .navigationBar)
    }
    .modelContainer(makeContainer())
    .onAppear {
        UserDefaults.standard.set("Ruben Luthman", forKey: "profileName")
    }
}

#Preview("ProfileView — tomt") {
    NavigationStack {
        ProfileView()
            .toolbar(.hidden, for: .navigationBar)
    }
    .modelContainer(makeContainer())
    .onAppear {
        UserDefaults.standard.removeObject(forKey: "profileName")
    }
}

// MARK: - ProgramEditorView

#Preview("ProgramEditorView — nytt") {
    ProgramEditorView(program: nil)
        .modelContainer(makeContainer())
}

// MARK: - ExercisePickerView

#Preview("ExercisePickerView") {
    ExercisePickerView { _ in }
}

// MARK: - GifSheet

#Preview("GifSheet — med GIF") {
    if let def = ExerciseDef.find(name: "Squats") {
        GifSheet(def: def)
    }
}

#Preview("GifSheet — utan GIF") {
    if let def = ExerciseDef.all.first(where: { !$0.hasGif }) {
        GifSheet(def: def)
    }
}

// MARK: - ProgramCard

#Preview("ProgramCard") {
    let container = makeContainer()
    let programs = try! container.mainContext.fetch(FetchDescriptor<WorkoutProgram>())
    return VStack(spacing: 12) {
        ForEach(programs) { p in
            ProgramCard(program: p)
        }
        ProgramCard(program: programs[0], isSelected: true, showCheckmark: true)
    }
    .padding(24)
    .modelContainer(container)
}

// MARK: - Onboarding

#Preview("OnboardingView") {
    OnboardingView()
        .modelContainer(makeContainer())
        .onAppear {
            UserDefaults.standard.set(false, forKey: "onboardingCompleted")
        }
}
