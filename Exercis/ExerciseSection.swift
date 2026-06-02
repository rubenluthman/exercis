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
    var onToggleCollapse: () -> Void
    @FocusState.Binding var activeField: WorkoutField?
    var onEdit: () -> Void = {}
    @State private var showGif = false

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
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .accessibilityHint("Öppnar övningsanimation")
                } else {
                    Text((form.def.shortName ?? form.def.displayName).uppercased())
                        .font(.jost(.semibold, size: 12))
                        .kerning(1.5)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                }
                Text("ÖKA")
                    .font(.jost(.medium, size: 9))
                    .kerning(1.5)
                    .foregroundColor(accent)
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
                        .foregroundColor(Color(.secondaryLabel))
                } else {
                    Text(form.def.repRange)
                        .font(.jost(.regular, size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(width: 90, alignment: .trailing)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, isCollapsed ? 14 : 16)

            if !isCollapsed {
                HStack(spacing: 0) {
                    Text("SET")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("KG")
                        .frame(width: 80, alignment: .leading)
                    Text("REPS")
                        .frame(width: 120, alignment: .trailing)
                }
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

                ForEach(Array(form.sets.indices), id: \.self) { i in
                    setRow(index: i)
                }

                Spacer().frame(height: 14)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isCollapsed)
        .onChange(of: form.sets.map(\.weight)) { _, weights in
            onEdit()
            guard form.shouldIncrease else { return }
            let newMax = weights.compactMap { parseWeight($0) }.max() ?? 0
            if newMax > form.previousMaxWeight {
                form.shouldIncrease = false
                UserDefaults.standard.setIncrease(form.def.name, false)
            }
        }
        .onChange(of: form.sets.map(\.reps)) { _, _ in
            onEdit()
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
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func setRow(index: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.jost(.semibold, size: 34))
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("", text: $form.sets[index].weight)
                .font(.jost(.semibold, size: 34))
                .foregroundColor(.primary)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .focused($activeField, equals: .weight(exercise: exerciseIndex, set: index))
                .frame(width: 80, alignment: .leading)
                .overlay(alignment: .leading) {
                    if form.sets[index].weight.isEmpty && activeField != .weight(exercise: exerciseIndex, set: index) {
                        Text("–")
                            .font(.jost(.semibold, size: 34))
                            .foregroundColor(Color(.tertiaryLabel))
                            .allowsHitTesting(false)
                    }
                }

            TextField("", text: $form.sets[index].reps)
                .font(.jost(.semibold, size: 34))
                .foregroundColor(.primary)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($activeField, equals: .reps(exercise: exerciseIndex, set: index))
                .frame(width: 120, alignment: .trailing)
                .overlay(alignment: .trailing) {
                    if form.sets[index].reps.isEmpty && activeField != .reps(exercise: exerciseIndex, set: index) {
                        Text("–")
                            .font(.jost(.semibold, size: 34))
                            .foregroundColor(Color(.tertiaryLabel))
                            .allowsHitTesting(false)
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
