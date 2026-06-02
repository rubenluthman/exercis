import SwiftUI
import SwiftData

struct ProgramEditorView: View {
    let program: WorkoutProgram?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var colorName: String
    @State private var exercises: [ExerciseDraft]
    @State private var showPicker = false
    @State private var showDeleteAlert = false

    init(program: WorkoutProgram?) {
        self.program = program
        _name = State(initialValue: program?.name ?? "")
        _colorName = State(initialValue: program?.colorName ?? "paletteIntenseRed")
        _exercises = State(initialValue: program?.sortedExercises.map {
            ExerciseDraft(exerciseId: $0.exerciseId, exerciseName: $0.exerciseName, setCount: $0.setCount)
        } ?? [])
    }

    private var accent: Color { Color(colorName) }
    private var isNew: Bool { program == nil }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Programnamn", text: $name)
                        .font(.body)
                }

                Section("Färg") {
                    colorPicker
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
                        Label("Lägg till övning", systemImage: "plus.circle.fill")
                            .foregroundStyle(accent)
                    }
                } header: {
                    HStack {
                        Text("ÖVNINGAR")
                        Spacer()
                        EditButton()
                            .font(.caption)
                            .foregroundStyle(accent)
                    }
                }

                if !isNew {
                    Section {
                        Button("Ta bort program", role: .destructive) {
                            showDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Nytt program" : "Redigera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klar") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { def in
                    exercises.append(ExerciseDraft(
                        exerciseId: def.id,
                        exerciseName: def.displayName,
                        setCount: 3
                    ))
                }
            }
            .alert("Ta bort \(program?.name ?? "program")?", isPresented: $showDeleteAlert) {
                Button("Ta bort", role: .destructive) { deleteProgram() }
                Button("Avbryt", role: .cancel) {}
            }
        }
    }

    // MARK: - Color picker

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(Color.programPalette.indices, id: \.self) { i in
                let name = paletteNames[i]
                let isSelected = colorName == name
                Button {
                    Haptics.selection()
                    colorName = name
                } label: {
                    Circle()
                        .fill(Color.programPalette[i])
                        .frame(width: 36, height: 36)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private let paletteNames = [
        "paletteIntenseRed", "paletteOrange", "paletteYellow", "paletteLime",
        "paletteGreen", "paletteTeal", "paletteCyan", "paletteLightBlue",
        "paletteDarkBlue", "palettePurple", "paletteMagenta", "palettePink"
    ]

    // MARK: - Exercise row

    private func exerciseRow(ex: Binding<ExerciseDraft>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.wrappedValue.exerciseName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text("\(ex.wrappedValue.setCount) set")
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if ex.wrappedValue.setCount > 1 {
                        ex.wrappedValue.setCount -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .foregroundStyle(ex.wrappedValue.setCount > 1 ? accent : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)

                Text("\(ex.wrappedValue.setCount)")
                    .font(.jost(.semibold, size: 17))
                    .foregroundStyle(accent)
                    .frame(width: 24, alignment: .center)

                Button {
                    if ex.wrappedValue.setCount < 6 {
                        ex.wrappedValue.setCount += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .foregroundStyle(ex.wrappedValue.setCount < 6 ? accent : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Logic

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let program {
            program.name = trimmed
            program.colorName = colorName
            for ex in program.exercises { context.delete(ex) }
            for (i, draft) in exercises.enumerated() {
                let pe = ProgramExercise(exerciseId: draft.exerciseId, exerciseName: draft.exerciseName, sortIndex: i, setCount: draft.setCount)
                pe.program = program
                context.insert(pe)
            }
        } else {
            let maxSort = (try? context.fetch(FetchDescriptor<WorkoutProgram>()))?.map(\.sortIndex).max() ?? -1
            let program = WorkoutProgram(name: trimmed, colorName: colorName, sortIndex: maxSort + 1)
            context.insert(program)
            for (i, draft) in exercises.enumerated() {
                let pe = ProgramExercise(exerciseId: draft.exerciseId, exerciseName: draft.exerciseName, sortIndex: i, setCount: draft.setCount)
                pe.program = program
                context.insert(pe)
            }
        }
        try? context.save()
        dismiss()
    }

    private func deleteProgram() {
        guard let program else { return }
        context.delete(program)
        try? context.save()
        dismiss()
    }
}

struct ExerciseDraft: Identifiable {
    let id = UUID()
    var exerciseId: String
    var exerciseName: String
    var setCount: Int
}
