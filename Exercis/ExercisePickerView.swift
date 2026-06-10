import SwiftUI
import Fuse

struct ExercisePickerView: View {
    let onSelect: (ExerciseDef) -> Void
    var programConstraint: ProgramConstraint = .none

    @Environment(\.dismiss) private var dismiss
    @AppStorage("bodyLimitations") private var bodyLimitationsRaw: String = ""

    @State private var searchText = ""
    @State private var selectedMuscleGroups: Set<String> = []
    @State private var selectedEquipment: Set<String> = []
    @State private var selectedMovements: Set<String> = []
    @State private var showMuscleFilter = false
    @State private var showEquipmentFilter = false
    @State private var showMovementFilter = false

    private let fuse = Fuse(threshold: 0.4)

    private var activeLimitations: Set<String> {
        Set(bodyLimitationsRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func isNotRecommended(_ def: ExerciseDef) -> Bool {
        let contraindicationsToAvoid = BodyLimitation.allCases
            .filter { activeLimitations.contains($0.rawValue) }
            .flatMap { $0.contraindications }
        if def.contraindications.contains(where: { contraindicationsToAvoid.contains($0) }) { return true }
        if programConstraint != .none && !programConstraint.matches(def) { return true }
        return false
    }

    private func passesFilters(_ def: ExerciseDef) -> Bool {
        if !selectedMuscleGroups.isEmpty {
            let groups = selectedMuscleGroups.compactMap { MuscleGroup(rawValue: $0) }
            guard groups.contains(where: { $0.matches(def) }) else { return false }
        }
        if !selectedEquipment.isEmpty {
            guard def.equipment.contains(where: { selectedEquipment.contains($0) }) else { return false }
        }
        if !selectedMovements.isEmpty {
            guard let movement = def.movement, selectedMovements.contains(movement) else { return false }
        }
        return true
    }

    private var allFiltered: [ExerciseDef] {
        let base: [ExerciseDef]
        if searchText.isEmpty {
            base = ExerciseDef.all
        } else {
            let searchStrings = ExerciseDef.all.map { "\($0.displayName) \($0.aliases.joined(separator: " ")) \($0.primaryMuscles.joined(separator: " "))" }
            let results = fuse.search(searchText, in: searchStrings)
            base = results.sorted { $0.score < $1.score }.map { ExerciseDef.all[$0.index] }
        }
        return base.filter { passesFilters($0) }
    }

    private var recommended: [ExerciseDef] { allFiltered.filter { !isNotRecommended($0) } }
    private var notRecommended: [ExerciseDef] { allFiltered.filter { isNotRecommended($0) } }
    private var hasActiveFilters: Bool { !selectedMuscleGroups.isEmpty || !selectedEquipment.isEmpty || !selectedMovements.isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChipRow
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                Divider()
                List {
                    if !recommended.isEmpty {
                        Section {
                            ForEach(recommended) { def in exerciseRow(def, dimmed: false) }
                        }
                    }
                    if !notRecommended.isEmpty {
                        Section {
                            ForEach(notRecommended) { def in exerciseRow(def, dimmed: true) }
                        } header: {
                            Text("NOT RECOMMENDED")
                                .font(.jost(.medium, size: 10))
                                .kerning(1.5)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Sök övning")
            .navigationTitle("Choose exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.jost(.regular, size: 16))
                }
            }
            .sheet(isPresented: $showMuscleFilter) {
                FilterSheet(
                    title: "MUSKELGRUPP",
                    options: MuscleGroup.allCases.map { ($0.displayName, $0.rawValue) },
                    selected: $selectedMuscleGroups
                )
            }
            .sheet(isPresented: $showEquipmentFilter) {
                FilterSheet(title: "REDSKAP", options: equipmentOptions, selected: $selectedEquipment)
            }
            .sheet(isPresented: $showMovementFilter) {
                FilterSheet(title: "RÖRELSE", options: movementOptions, selected: $selectedMovements)
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Filter chip row

    private var filterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "MUSKEL", count: selectedMuscleGroups.count) { showMuscleFilter = true }
                filterChip(label: "REDSKAP", count: selectedEquipment.count) { showEquipmentFilter = true }
                filterChip(label: "RÖRELSE", count: selectedMovements.count) { showMovementFilter = true }
                if hasActiveFilters {
                    Button {
                        selectedMuscleGroups = []
                        selectedEquipment = []
                        selectedMovements = []
                    } label: {
                        Text("CLEAR")
                            .font(.jost(.regular, size: 11))
                            .kerning(1)
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(label: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(count > 0 ? "\(String(localized: String.LocalizationValue(label))) \(count)" : String(localized: String.LocalizationValue(label)))
                    .font(.jost(.semibold, size: 11))
                    .kerning(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(count > 0 ? .white : Color(.label))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(count > 0 ? Color.homeAccent : Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise row

    private func exerciseRow(_ def: ExerciseDef, dimmed: Bool) -> some View {
        Button {
            onSelect(def)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(def.displayName)
                    .foregroundStyle(.primary)
                if !def.primaryMuscles.isEmpty {
                    Text(def.primaryMuscles.map { muscleLabel($0) }.joined(separator: ", "))
                        .font(.jost(.regular, size: 12))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
            .padding(.vertical, 2)
            .opacity(dimmed ? 0.4 : 1)
        }
        .buttonStyle(.plain)
    }

    private func muscleLabel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    // MARK: - Filter data

    private let equipmentOptions: [(String, String)] = [
        ("SKIVSTÅNG", "barbell"),
        ("HANTEL", "dumbbell"),
        ("KABEL", "cable"),
        ("MASKIN", "machine"),
        ("KROPPSVIKT", "bodyweight"),
        ("KETTLEBELL", "kettlebell"),
        ("PULL-UP-STÅNG", "pull_up_bar"),
        ("DIP-STÅNG", "dip_bar"),
        ("GUMMIBAND", "resistance_band"),
        ("SMITH-MASKIN", "smith_machine")
    ]

    private let movementOptions: [(String, String)] = [
        ("TRYCK", "push"),
        ("DRAG", "pull"),
        ("GÅNG (HINGE)", "hinge"),
        ("SQUAT", "squat"),
        ("ROTATION", "rotation"),
        ("FLEXION", "flexion"),
        ("ISOMETRISK", "isometric"),
        ("MASKIN", "machine"),
        ("CARRY", "carry")
    ]
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    let title: String
    let options: [(String, String)]
    @Binding var selected: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(options, id: \.1) { display, raw in
                Button {
                    if selected.contains(raw) { selected.remove(raw) } else { selected.insert(raw) }
                    Haptics.selection()
                } label: {
                    HStack {
                        Text(display)
                            .font(.jost(.semibold, size: 12))
                            .kerning(1.5)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected.contains(raw) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.homeAccent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .font(.jost(.semibold, size: 16))
                }
                if !selected.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Rensa") { selected.removeAll() }
                            .font(.jost(.regular, size: 16))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
