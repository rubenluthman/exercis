import SwiftUI
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.exercis", category: "SwiftData")

struct ProgramEditorView: View {
    let program: WorkoutProgram?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var colorName: String
    @State private var constraintRaw: String
    @State private var useFixedReps: Bool
    @State private var defaultFixedReps: Int
    @State private var exercises: [ExerciseDraft]
    @State private var showPicker = false
    @State private var showDeleteAlert = false
    @State private var showResetAlert = false

    init(program: WorkoutProgram?) {
        self.program = program
        _name = State(initialValue: program?.name ?? "")
        let cn = program?.colorName ?? "paletteIntenseRed"
        _colorName = State(initialValue: ProgramColor(rawValue: cn) != nil ? cn : "paletteIntenseRed")
        _constraintRaw = State(initialValue: program?.programConstraint ?? "")
        _useFixedReps = State(initialValue: program?.useFixedReps ?? false)
        let existingReps = program?.sortedExercises.first?.fixedReps ?? 0
        _defaultFixedReps = State(initialValue: existingReps > 0 ? existingReps : 6)
        _exercises = State(initialValue: program?.sortedExercises.map {
            ExerciseDraft(exerciseId: $0.exerciseId, exerciseName: $0.exerciseName, setCount: $0.setCount, fixedReps: $0.fixedReps)
        } ?? [])
    }

    private var accent: Color { Color(colorName) }
    private var isNew: Bool { program == nil }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Program name", text: $name)
                        .font(.jost(.regular, size: 16))
                }

                Section("Färg") {
                    colorPicker
                }

                Section("Begränsning") {
                    constraintPicker
                }

                Section {
                    Toggle(isOn: $useFixedReps) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Locked reps")
                                .font(.jost(.regular, size: 16))
                            Text("Set a fixed rep count per exercise")
                                .font(.jost(.regular, size: 13))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    .tint(accent)
                    .onChange(of: useFixedReps) { _, enabled in
                        if enabled {
                            for i in exercises.indices {
                                exercises[i].fixedReps = defaultFixedReps
                            }
                        }
                    }
                    if useFixedReps {
                        Stepper(value: $defaultFixedReps, in: 1...25) {
                            HStack(spacing: 6) {
                                Text("\(defaultFixedReps)")
                                    .font(.jost(.semibold, size: 16))
                                    .foregroundStyle(accent)
                                Text("reps")
                                    .font(.jost(.regular, size: 16))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .tint(accent)
                        .onChange(of: defaultFixedReps) { _, newVal in
                            for i in exercises.indices {
                                exercises[i].fixedReps = newVal
                            }
                        }
                    }
                }

                Section {
                    ForEach($exercises) { $ex in
                        exerciseRow(ex: $ex)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { offsets in
                        exercises.remove(atOffsets: offsets)
                    }

                    Button {
                        showPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundStyle(accent)
                    }
                } header: {
                    HStack {
                        Text("EXERCISES")
                        Spacer()
                        EditButton()
                            .font(.jost(.regular, size: 12))
                            .foregroundStyle(accent)
                    }
                }

                if !isNew, let pid = program?.id, defaultProgramDef(for: pid) != nil {
                    Section {
                        Button("Reset to defaults") {
                            showResetAlert = true
                        }
                        .foregroundStyle(accent)
                    }
                }

                if !isNew {
                    Section {
                        Button("Delete Program", role: .destructive) {
                            showDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New program" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.jost(.regular, size: 16))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(.jost(.semibold, size: 16))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView(
                    onSelect: { def in
                        exercises.append(ExerciseDraft(
                            exerciseId: def.id,
                            exerciseName: def.displayName,
                            setCount: 3,
                            fixedReps: useFixedReps ? defaultFixedReps : 0
                        ))
                    },
                    programConstraint: ProgramConstraint(rawValue: constraintRaw) ?? .none
                )
            }
            .alert(String(localized: "Reset to defaults?"), isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { resetToDefaults() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore the original exercises, name, color and settings.")
            }
            .alert(String(format: String(localized: "Delete %@?"), program?.name ?? ""), isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { deleteProgram() }
                Button("Cancel", role: .cancel) {}
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Constraint picker

    private var constraintPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProgramConstraint.allCases, id: \.rawValue) { c in
                    let isSelected = constraintRaw == c.rawValue
                    Button {
                        Haptics.selection()
                        constraintRaw = c.rawValue
                    } label: {
                        Text(c.displayName)
                            .font(.jost(.semibold, size: 12))
                            .kerning(1)
                            .foregroundStyle(isSelected ? .white : Color(.label))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? accent : Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Color picker

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(ProgramColor.allCases, id: \.rawValue) { pc in
                let isSelected = colorName == pc.rawValue
                Button {
                    Haptics.selection()
                    colorName = pc.rawValue
                } label: {
                    Circle()
                        .fill(pc.color)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.jost(.bold, size: 14))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Exercise row

    private func exerciseRow(ex: Binding<ExerciseDraft>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.wrappedValue.exerciseName)
                    .font(.jost(.regular, size: 16))
                    .foregroundStyle(.primary)
                Group {
                    if useFixedReps {
                        Text("\(ex.wrappedValue.setCount) set · \(ex.wrappedValue.fixedReps) reps")
                    } else {
                        Text("\(ex.wrappedValue.setCount) set")
                    }
                }
                .font(.jost(.regular, size: 12))
                .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            HStack(spacing: 0) {
                setsStepper(ex: ex)

                if !useFixedReps {
                    repsStepper(ex: ex)
                }

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 2)
    }

    private func setsStepper(ex: Binding<ExerciseDraft>) -> some View {
        HStack(spacing: 0) {
            Button {
                if ex.wrappedValue.setCount > 1 { ex.wrappedValue.setCount -= 1 }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 32, height: 32)
                    .foregroundStyle(ex.wrappedValue.setCount > 1 ? accent : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease set count")

            Text("\(ex.wrappedValue.setCount)")
                .font(.jost(.semibold, size: 17))
                .foregroundStyle(accent)
                .frame(width: 24, alignment: .center)

            Button {
                if ex.wrappedValue.setCount < 6 { ex.wrappedValue.setCount += 1 }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 32, height: 32)
                    .foregroundStyle(ex.wrappedValue.setCount < 6 ? accent : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase set count")
        }
    }

    private func repsStepper(ex: Binding<ExerciseDraft>) -> some View {
        HStack(spacing: 0) {
            Text("·")
                .font(.jost(.regular, size: 17))
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 12)

            Button {
                if ex.wrappedValue.fixedReps > 1 { ex.wrappedValue.fixedReps -= 1 }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 28, height: 32)
                    .foregroundStyle(ex.wrappedValue.fixedReps > 1 ? accent : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease fixed reps")

            Text("\(ex.wrappedValue.fixedReps)")
                .font(.jost(.semibold, size: 17))
                .foregroundStyle(accent)
                .frame(width: 28, alignment: .center)

            Button {
                if ex.wrappedValue.fixedReps < 30 { ex.wrappedValue.fixedReps += 1 }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 32)
                    .foregroundStyle(ex.wrappedValue.fixedReps < 30 ? accent : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase fixed reps")
        }
    }

    // MARK: - Logic

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let program {
            program.name = trimmed
            program.colorName = colorName
            program.programConstraint = constraintRaw
            program.useFixedReps = useFixedReps
            for ex in program.exercises { context.delete(ex) }
            for (i, draft) in exercises.enumerated() {
                let fr = useFixedReps ? draft.fixedReps : 0
                let pe = ProgramExercise(exerciseId: draft.exerciseId, exerciseName: draft.exerciseName, sortIndex: i, setCount: draft.setCount, fixedReps: fr)
                pe.program = program
                context.insert(pe)
            }
        } else {
            let maxSort = (try? context.fetch(FetchDescriptor<WorkoutProgram>()))?.map(\.sortIndex).max() ?? -1
            let program = WorkoutProgram(name: trimmed, colorName: colorName, sortIndex: maxSort + 1, programConstraint: constraintRaw)
            program.useFixedReps = useFixedReps
            context.insert(program)
            for (i, draft) in exercises.enumerated() {
                let fr = useFixedReps ? draft.fixedReps : 0
                let pe = ProgramExercise(exerciseId: draft.exerciseId, exerciseName: draft.exerciseName, sortIndex: i, setCount: draft.setCount, fixedReps: fr)
                pe.program = program
                context.insert(pe)
            }
        }
        do { try context.save() } catch {
            #if DEBUG
            logger.error("context.save failed: \(error)")
            #endif
        }
        dismiss()
    }

    private func resetToDefaults() {
        guard let program, let def = defaultProgramDef(for: program.id) else { return }
        name = def.name
        colorName = def.color
        constraintRaw = def.constraint
        useFixedReps = false
        exercises = def.exercises.map { ExerciseDraft(exerciseId: $0.id, exerciseName: $0.name, setCount: $0.setCount, fixedReps: 0) }
    }

    private func deleteProgram() {
        guard let program else { return }
        context.delete(program)
        do { try context.save() } catch {
            #if DEBUG
            logger.error("context.save failed: \(error)")
            #endif
        }
        dismiss()
    }
}

struct ExerciseDraft: Identifiable {
    let id = UUID()
    var exerciseId: String
    var exerciseName: String
    var setCount: Int
    var fixedReps: Int = 0
}
