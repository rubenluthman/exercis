import SwiftUI

enum WorkoutField: Hashable {
    case weight(exercise: Int, set: Int)
    case reps(exercise: Int, set: Int)
}

struct ExerciseSection: View {
    @Binding var form: ExerciseFormData
    var exerciseIndex: Int
    var isCollapsed: Bool
    var accent: Color = .homeAccent
    var fixedReps: Int = 0
    var onToggleCollapse: () -> Void
    @FocusState.Binding var activeField: WorkoutField?
    var onEdit: () -> Void = {}
    var onSwapExercise: (() -> Void)? = nil
    @State private var showGif = false
    @AppStorage("useImperialUnits") private var imperial = false

    var body: some View {
        VStack(spacing: 0) {

            HStack(alignment: .firstTextBaseline) {
                if form.def.hasGif {
                    Button((form.def.shortName ?? form.def.displayName).uppercased()) {
                        showGif = true
                    }
                    .buttonStyle(.plain)
                    .font(.jost(.semibold, size: 12))
                    .kerning(1.5)
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .accessibilityHint(String(localized: "Opens exercise animation"))
                } else {
                    Text((form.def.shortName ?? form.def.displayName).uppercased())
                        .font(.jost(.semibold, size: 12))
                        .kerning(1.5)
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)
                }
                Text("INCREASE")
                    .font(.jost(.medium, size: 9))
                    .kerning(1.5)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(accent, lineWidth: 0.5)
                    )
                    .opacity(form.shouldIncrease ? 1 : 0)
                Spacer()
                if isCollapsed {
                    Image(systemName: "chevron.right")
                        .font(.jost(.medium, size: 10))
                        .foregroundStyle(Color(.secondaryLabel))
                } else {
                    HStack(spacing: 10) {
                        Text(form.def.repRange)
                            .font(.jost(.regular, size: 12))
                            .foregroundStyle(Color(.secondaryLabel))
                        if let swap = onSwapExercise {
                            Button(action: swap) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Switch exercise")
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, isCollapsed ? 14 : 16)

            if !isCollapsed {
                HStack(spacing: 0) {
                    Text("SET")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(weightLabel(imperial))
                        .frame(width: 80, alignment: .leading)
                    Text("REPS")
                        .frame(width: 120, alignment: .trailing)
                }
                .font(.jost(.medium, size: 11))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

                ForEach(Array(form.sets.indices), id: \.self) { i in
                    setRow(index: i)
                }

                Spacer().frame(height: 14)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isCollapsed)
        .onChange(of: form.sets.map(\.weight)) { old, new in
            onEdit()
            if let i = (0..<min(old.count, new.count)).first(where: { old[$0] != new[$0] }) {
                let oldVal = old[i]
                for j in (i + 1)..<form.sets.count where form.sets[j].weight == oldVal {
                    form.sets[j].weight = new[i]
                }
            }
            guard form.shouldIncrease else { return }
            let newMax = new.compactMap { parseWeight($0) }.max() ?? 0
            if newMax > form.previousMaxWeight {
                form.shouldIncrease = false
                UserDefaults.standard.setIncrease(form.def.name, false)
            }
        }
        .onChange(of: form.sets.map(\.reps)) { old, new in
            onEdit()
            if let i = (0..<min(old.count, new.count)).first(where: { old[$0] != new[$0] }) {
                let oldVal = old[i]
                for j in (i + 1)..<form.sets.count where form.sets[j].reps == oldVal {
                    form.sets[j].reps = new[i]
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onToggleCollapse() }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                Haptics.impact(.medium)
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    form.shouldIncrease.toggle()
                }
                UserDefaults.standard.setIncrease(form.def.name, form.shouldIncrease)
            }
        )
        .sheet(isPresented: $showGif) {
            GifSheet(def: form.def)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var hasSuggestion: Bool {
        !form.suggestedWeight.isEmpty && !form.suggestedReps.isEmpty
    }

    private func isSuggestionVisible(index: Int) -> Bool {
        guard hasSuggestion else { return false }
        return form.sets[index].weight.isEmpty && form.sets[index].reps.isEmpty
    }

    @ViewBuilder
    private func setRow(index: Int) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(index + 1)")
                    .font(.jost(.semibold, size: 34))
                    .foregroundStyle(Color(.secondaryLabel))

                if isSuggestionVisible(index: index) {
                    Text("→ \(form.suggestedWeight) × \(form.suggestedReps)")
                        .font(.jost(.medium, size: 9))
                        .kerning(1)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(accent.opacity(0.5), lineWidth: 0.5)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.18), value: isSuggestionVisible(index: index))

            TextField("", text: $form.sets[index].weight)
                .font(.jost(.semibold, size: 34))
                .foregroundStyle(.primary)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .focused($activeField, equals: .weight(exercise: exerciseIndex, set: index))
                .frame(width: 80, alignment: .leading)
                .overlay(alignment: .leading) {
                    if form.sets[index].weight.isEmpty && activeField != .weight(exercise: exerciseIndex, set: index) {
                        Text("–")
                            .font(.jost(.semibold, size: 34))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .allowsHitTesting(false)
                    }
                }

            if fixedReps > 0 && !form.sets[index].repsUnlocked {
                Text("\(fixedReps)")
                    .font(.jost(.semibold, size: 34))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(width: 120, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.5) {
                        Haptics.impact(.medium)
                        form.sets[index].repsUnlocked = true
                        activeField = .reps(exercise: exerciseIndex, set: index)
                    }
            } else {
                TextField("", text: $form.sets[index].reps)
                    .font(.jost(.semibold, size: 34))
                    .foregroundStyle(fixedReps > 0 ? accent : .primary)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($activeField, equals: .reps(exercise: exerciseIndex, set: index))
                    .frame(width: 120, alignment: .trailing)
                    .overlay(alignment: .trailing) {
                        if form.sets[index].reps.isEmpty && activeField != .reps(exercise: exerciseIndex, set: index) {
                            Text("–")
                                .font(.jost(.semibold, size: 34))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 2)
    }
}

extension UserDefaults {
    static let increaseKey = "increaseExercises"

    func increaseNames() -> Set<String> {
        Set(stringArray(forKey: Self.increaseKey) ?? [])
    }

    func setIncrease(_ name: String, _ value: Bool) {
        var names = increaseNames()
        if value { names.insert(name) } else { names.remove(name) }
        set(Array(names), forKey: Self.increaseKey)
    }
}
