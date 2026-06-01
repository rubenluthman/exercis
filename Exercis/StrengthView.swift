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
    let program: WorkoutProgram
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
    private var sessions: [WorkoutSession]

    @AppStorage("hasDraft") private var hasDraft = false
    @State private var exerciseForms: [ExerciseFormData] = []

    private var accent: Color { Color(program.colorName) }
    @State private var collapsedExercises: Set<Int> = []
    @State private var initialized = false
    @State private var startTime = Date()
    @State private var isDirty = false
    @State private var showEffortPicker = false
    @State private var showTimePicker = false
    @State private var editedStart: Date = Date()
    @State private var editedEnd: Date = Date()
    @State private var hasCustomTime = false
    @State private var lastEffortScore = 5
    @State private var effortDragOffset: CGFloat = 0
    @State private var didCompleteSession = false
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
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    ThinDivider().padding(.top, 8)

                    ForEach(exerciseForms.indices, id: \.self) { i in
                        ExerciseSection(
                            form: $exerciseForms[i],
                            exerciseIndex: i,
                            isCollapsed: collapsedExercises.contains(i),
                            accent: accent,
                            onToggleCollapse: {
                                UISelectionFeedbackGenerator().selectionChanged()
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
                        .opacity(showEffortPicker ? 0 : 1)
                }
            }
            .softScrollEdge()

            if showEffortPicker {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        saveSession(effortScore: nil)
                        dismiss()
                    }
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 36, height: 4)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        EffortPickerSheet(accent: accent, initialScore: lastEffortScore) { score in
                            if let score { UserDefaults.standard.set(score, forKey: "workoutEffortScore") }
                            saveSession(effortScore: score)
                            dismiss()
                        }
                    }
                    .background(Color.appBackground)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                }
                .offset(y: max(0, effortDragOffset))
                .animation(.interactiveSpring(), value: effortDragOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            var t = Transaction()
                            t.disablesAnimations = true
                            withTransaction(t) { effortDragOffset = value.translation.height }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                saveSession(effortScore: nil)
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { effortDragOffset = 0 }
                            }
                        }
                )
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showEffortPicker)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("NÄSTA") {
                    UISelectionFeedbackGenerator().selectionChanged()
                    activeField = nextField
                }
                    .font(.jost(.semibold, size: 13))
                    .foregroundColor(nextField != nil ? accent : Color(.tertiaryLabel))
                    .disabled(nextField == nil)
                Button("KLAR") { activeField = nil }
                    .font(.jost(.semibold, size: 13))
                    .foregroundColor(accent)
            }
        }
        .sheet(isPresented: $showTimePicker, onDismiss: { hasCustomTime = true }) {
            SessionTimePicker(start: $editedStart, end: $editedEnd, accent: accent)
        }
        .onAppear {
            guard !initialized else { return }
            buildForms(from: sessions.first)
            editedStart = startTime
            editedEnd = Date()
            initialized = true
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
        .onDisappear {
            saveDraftIfNeeded()
        }
    }

    // MARK: Sub-views

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(program.name.uppercased())
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundColor(.primary)

            Button {
                showTimePicker = true
            } label: {
                Text(editedEnd.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "sv_SE"))).uppercased())
                    .font(.jost(.regular, size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)

            Spacer()

            Button("←") {
                saveDraftAndReturn()
            }
            .font(.jost(.regular, size: 22))
            .foregroundColor(Color(.secondaryLabel))
            .frame(width: 90, height: 44, alignment: .trailing)
            .accessibilityLabel("Tillbaka")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var klarBar: some View {
        Button("KLAR") {
            let hasAnyData = exerciseForms.contains { $0.sets.contains { !$0.weight.isEmpty || !$0.reps.isEmpty } }
            if hasAnyData {
                activeField = nil
                let saved = UserDefaults.standard.integer(forKey: "workoutEffortScore")
                lastEffortScore = saved > 0 ? saved : 5
                showEffortPicker = true
            } else {
                dismiss()
            }
        }
        .buttonStyle(FilledButtonStyle(accent: accent))
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: Logic

    private func buildForms(from session: WorkoutSession?) {
        let defs = program.sortedExercises.compactMap { pe in
            ExerciseDef.find(id: pe.exerciseId) ?? ExerciseDef.find(name: pe.exerciseName)
        }
        let setCount = program.sortedExercises.first?.setCount ?? 3

        if hasDraft, let draft = UserDefaults.standard.loadDraft(),
           draft.programId == program.id.uuidString {
            startTime = draft.startTime
            collapsedExercises = Set(draft.collapsedExercises)
            exerciseForms = defs.map { def in
                if let ex = draft.exercises.first(where: { $0.name == def.name }) {
                    return ExerciseFormData(
                        def: def,
                        sets: ex.sets.map { SetFormData(weight: $0.weight, reps: $0.reps) },
                        shouldIncrease: ex.shouldIncrease,
                        previousMaxWeight: ex.previousMaxWeight
                    )
                }
                return ExerciseFormData(def: def, sets: Array(repeating: SetFormData(), count: setCount))
            }
            return
        }

        startTime = Date()
        exerciseForms = defs.map { def in
            var sets = Array(repeating: SetFormData(), count: setCount)

            if let session,
               let log = session.exerciseLogs.first(where: { $0.name == def.name }),
               let maxWeight = log.sets.filter({ $0.weight > 0 }).map(\.weight).max(),
               let bestSet = log.sets.filter({ $0.weight == maxWeight }).max(by: { $0.reps < $1.reps }) {
                let w = formatWeight(bestSet.weight)
                let r = bestSet.reps > 0 ? "\(bestSet.reps)" : ""
                sets = Array(repeating: SetFormData(weight: w, reps: r), count: setCount)
            }

            let increase = UserDefaults.standard.increaseNames().contains(def.name)
            let prevMax = session?.exerciseLogs
                .first(where: { $0.name == def.name })?
                .sets.map(\.weight).max() ?? 0
            return ExerciseFormData(def: def, sets: sets, shouldIncrease: increase, previousMaxWeight: prevMax)
        }
    }

    private func saveDraftIfNeeded() {
        guard !didCompleteSession else { return }
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
                collapsedExercises: Array(collapsedExercises),
                programId: program.id.uuidString
            )
            UserDefaults.standard.saveDraft(draft)
            hasDraft = true
        } else if !hasAnyData {
            UserDefaults.standard.saveDraft(nil)
            hasDraft = false
        }
    }

    private func saveDraftAndReturn() {
        saveDraftIfNeeded()
        dismiss()
    }

    private func saveSession(effortScore: Int? = nil) {
        let hasAnyData = exerciseForms.contains { $0.sets.contains { !$0.weight.isEmpty || !$0.reps.isEmpty } }
        guard hasAnyData else { return }

        didCompleteSession = true
        let end = hasCustomTime && editedEnd > editedStart ? editedEnd : Date()
        let start: Date
        if hasCustomTime {
            start = editedStart < end ? editedStart : end.addingTimeInterval(-3600)
        } else if end.timeIntervalSince(editedStart) > 3 * 3600 {
            start = end.addingTimeInterval(-3600)
        } else {
            start = editedStart
        }
        let session = WorkoutSession(date: end)
        session.startDate = start
        session.programId = program.id
        session.programName = program.name
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

        if UserDefaults.standard.bool(forKey: "healthKitSyncEnabled") {
            let capturedStart = start
            let capturedEnd = end
            let capturedSession = session
            Task { @MainActor in
                let uuid = await HealthKitManager.shared.saveWorkout(start: capturedStart, end: capturedEnd, effortScore: effortScore)
                capturedSession.healthKitID = uuid
                try? context.save()
            }
        }
    }
}

struct EffortPickerSheet: View {
    let accent: Color
    let onSelect: (Int?) -> Void
    @State private var selectedScore: Int

    init(accent: Color, initialScore: Int = 5, onSelect: @escaping (Int?) -> Void) {
        self.accent = accent
        self.onSelect = onSelect
        self._selectedScore = State(initialValue: initialScore)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ANSTRÄNGNING")
                .font(.jost(.bold, size: 13))
                .kerning(2)
                .foregroundColor(accent)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 6)

            Text("HUR JOBBIGT VAR PASSET?")
                .font(.jost(.regular, size: 11))
                .kerning(1.5)
                .foregroundColor(Color(.secondaryLabel))
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

            Button("KLAR") {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onSelect(selectedScore)
            }
            .buttonStyle(FilledButtonStyle(accent: accent))
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Button("HOPPA ÖVER") {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onSelect(nil)
            }
            .font(.jost(.regular, size: 12))
            .kerning(1.5)
            .foregroundColor(Color(.secondaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    let ctx = container.mainContext

    let session = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
    ctx.insert(session)
    let log = ExerciseLog(name: "Barbell Back Squat", orderIndex: 0)
    log.session = session
    ctx.insert(log)
    for (i, (w, r)) in [(90.0, 7), (90.0, 6), (87.5, 6)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r)
        s.exerciseLog = log
        ctx.insert(s)
    }

    let program = WorkoutProgram(name: "Push", colorName: "paletteIntenseRed")
    program.exercises = [
        ProgramExercise(exerciseId: "wger_bench_press", exerciseName: "Bench Press", sortIndex: 0)
    ]
    ctx.insert(program)
    return StrengthView(program: program)
        .modelContainer(container)
}
