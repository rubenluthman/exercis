import SwiftUI
import SwiftData

// MARK: - Form Data

struct SetFormData: Identifiable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""
}

struct ExerciseFormData: Identifiable {
    let id = UUID()
    let def: ExerciseDef
    var sets: [SetFormData]
    var shouldIncrease: Bool = false
    var previousMaxWeight: Double = 0
}

// MARK: - StrengthView

struct StrengthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
    private var sessions: [WorkoutSession]

    @AppStorage("hasDraft") private var hasDraft = false
    @State private var exerciseForms: [ExerciseFormData] = []
    @State private var collapsedExercises: Set<Int> = []
    @State private var initialized = false
    @State private var startTime = Date()
    @State private var isDirty = false
    @State private var showEffortPicker = false
    @FocusState private var activeField: WorkoutField?

    private var nextField: WorkoutField? {
        guard let current = activeField else { return nil }
        switch current {
        case .weight(let ex, let set):
            return .reps(exercise: ex, set: set)
        case .reps(let ex, let set):
            let nextSet = set + 1
            if nextSet < exerciseForms[ex].sets.count {
                return .weight(exercise: ex, set: nextSet)
            }
            let nextEx = ex + 1
            if nextEx < exerciseForms.count {
                return .weight(exercise: nextEx, set: 0)
            }
            return nil
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    ThinDivider().padding(.top, 8)

                    ForEach(exerciseForms.indices, id: \.self) { i in
                        ExerciseSection(
                            form: $exerciseForms[i],
                            exerciseIndex: i,
                            isCollapsed: collapsedExercises.contains(i),
                            onToggleCollapse: {
                                activeField = nil
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    if collapsedExercises.contains(i) {
                                        collapsedExercises.remove(i)
                                    } else {
                                        collapsedExercises.insert(i)
                                    }
                                }
                            },
                            activeField: $activeField,
                            onEdit: { isDirty = true }
                        )
                        ThinDivider()
                    }

                    klarBar
                }
            }

            if showEffortPicker {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color(white: 0.75))
                            .frame(width: 36, height: 4)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        EffortPickerSheet { score in
                            saveSession(effortScore: score)
                            dismiss()
                        }
                    }
                    .background(Color.appBackground)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showEffortPicker)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("NÄSTA") { activeField = nextField }
                    .font(.jost(.semibold, size: 13))
                    .foregroundColor(nextField != nil ? Color.homeAccent : Color(white: 0.7))
                    .disabled(nextField == nil)
                Button("KLAR") { activeField = nil }
                    .font(.jost(.semibold, size: 13))
                    .foregroundColor(Color.homeAccent)
            }
        }
        .onAppear {
            guard !initialized else { return }
            buildForms(from: sessions.first)
            initialized = true
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
    }

    // MARK: Sub-views

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("STYRKETRÄNING")
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundColor(.black)

            Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "sv_SE"))).uppercased())
                .font(.jost(.regular, size: 13))
                .foregroundColor(Color(white: 0.45))

            Spacer()

            Button("←") {
                saveDraftAndReturn()
            }
            .font(.jost(.regular, size: 22))
            .foregroundColor(Color(white: 0.5))
            .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var klarBar: some View {
        Button("KLAR") {
            let hasAnyData = exerciseForms.contains { $0.sets.contains { !$0.weight.isEmpty || !$0.reps.isEmpty } }
            if hasAnyData {
                activeField = nil
                showEffortPicker = true
            } else {
                dismiss()
            }
        }
        .buttonStyle(FilledButtonStyle(accent: Color.homeAccent))
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: Logic

    private func buildForms(from session: WorkoutSession?) {
        if hasDraft, let draft = UserDefaults.standard.loadDraft() {
            startTime = draft.startTime
            collapsedExercises = Set(draft.collapsedExercises)
            exerciseForms = ExerciseDef.all.map { def in
                if let ex = draft.exercises.first(where: { $0.name == def.name }) {
                    return ExerciseFormData(
                        def: def,
                        sets: ex.sets.map { SetFormData(weight: $0.weight, reps: $0.reps) },
                        shouldIncrease: ex.shouldIncrease,
                        previousMaxWeight: ex.previousMaxWeight
                    )
                }
                return ExerciseFormData(def: def, sets: [SetFormData(), SetFormData(), SetFormData()])
            }
            return
        }

        startTime = Date()
        exerciseForms = ExerciseDef.all.map { def in
            var sets: [SetFormData] = []

            if let session,
               let log = session.exerciseLogs.first(where: { $0.name == def.name }) {
                sets = log.sets
                    .sorted { $0.setNumber < $1.setNumber }
                    .map { s in
                        SetFormData(
                            weight: s.weight > 0 ? formatWeight(s.weight) : "",
                            reps:   s.reps > 0   ? "\(s.reps)"           : ""
                        )
                    }
            }

            if sets.isEmpty { sets = [SetFormData(), SetFormData(), SetFormData()] }

            let increase = UserDefaults.standard.increaseNames().contains(def.name)
            let prevMax = session?.exerciseLogs
                .first(where: { $0.name == def.name })?
                .sets.map(\.weight).max() ?? 0
            return ExerciseFormData(def: def, sets: sets, shouldIncrease: increase, previousMaxWeight: prevMax)
        }
    }

    private func saveDraftAndReturn() {
        let hasAnyData = exerciseForms.contains { $0.sets.contains { !$0.weight.isEmpty || !$0.reps.isEmpty } }

        if (isDirty || hasDraft) && hasAnyData {
            let draft = WorkoutDraft(
                exercises: exerciseForms.map { form in
                    WorkoutDraft.ExerciseDraft(
                        name: form.def.name,
                        sets: form.sets.map { WorkoutDraft.SetDraft(weight: $0.weight, reps: $0.reps) },
                        shouldIncrease: form.shouldIncrease,
                        previousMaxWeight: form.previousMaxWeight
                    )
                },
                startTime: startTime,
                collapsedExercises: Array(collapsedExercises)
            )
            UserDefaults.standard.saveDraft(draft)
            hasDraft = true
        } else if !hasAnyData {
            UserDefaults.standard.saveDraft(nil)
            hasDraft = false
        }

        dismiss()
    }

    private func saveSession(effortScore: Int? = nil) {
        let hasAnyData = exerciseForms.contains { $0.sets.contains { !$0.weight.isEmpty || !$0.reps.isEmpty } }
        guard hasAnyData else { return }

        let session = WorkoutSession(date: Date())
        context.insert(session)

        for (i, form) in exerciseForms.enumerated() {
            let hasData = form.sets.contains { !$0.weight.isEmpty || !$0.reps.isEmpty }
            guard hasData else { continue }

            let log = ExerciseLog(name: form.def.name, orderIndex: i)
            log.session = session
            context.insert(log)

            for (j, s) in form.sets.enumerated() {
                let setLog = SetLog(
                    setNumber: j + 1,
                    weight:    parseWeight(s.weight) ?? 0,
                    reps:      Int(s.reps) ?? 0
                )
                setLog.exerciseLog = log
                context.insert(setLog)
            }

            if form.shouldIncrease {
                let prevMax = sessions.first?
                    .exerciseLogs.first(where: { $0.name == form.def.name })?
                    .sets.map(\.weight).max() ?? 0
                let newMax = form.sets.compactMap { parseWeight($0.weight) }.max() ?? 0
                if newMax > prevMax {
                    UserDefaults.standard.setIncrease(form.def.name, false)
                }
            }
        }

        session.effortScore = effortScore
        try? context.save()

        UserDefaults.standard.saveDraft(nil)
        hasDraft = false

        let capturedStart = startTime
        let capturedEnd = Date()
        let capturedSession = session
        Task { @MainActor in
            let uuid = await HealthKitManager.shared.saveWorkout(start: capturedStart, end: capturedEnd, effortScore: effortScore)
            capturedSession.healthKitID = uuid
            try? context.save()
        }
    }
}

private struct EffortPickerSheet: View {
    let onSelect: (Int?) -> Void
    @State private var selectedScore = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ANSTRÄNGNING")
                .font(.jost(.bold, size: 13))
                .kerning(2)
                .foregroundColor(Color.homeAccent)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 6)

            Text("HUR JOBBIGT VAR PASSET?")
                .font(.jost(.regular, size: 11))
                .kerning(1.5)
                .foregroundColor(Color(white: 0.5))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            ThinDivider()

            Picker("", selection: $selectedScore) {
                ForEach(1...10, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)

            ThinDivider()

            Button("SPARA") {
                onSelect(selectedScore)
            }
            .buttonStyle(FilledButtonStyle(accent: Color.homeAccent))
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Button("HOPPA ÖVER") {
                onSelect(nil)
            }
            .font(.jost(.regular, size: 12))
            .kerning(1.5)
            .foregroundColor(Color(white: 0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    let ctx = container.mainContext

    let session = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
    ctx.insert(session)
    let log = ExerciseLog(name: "Safety Bar Squat", orderIndex: 0)
    log.session = session
    ctx.insert(log)
    for (i, (w, r)) in [(90.0, 7), (90.0, 6), (87.5, 6)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r)
        s.exerciseLog = log
        ctx.insert(s)
    }

    return NavigationStack {
        StrengthView()
            .modelContainer(container)
    }
}
