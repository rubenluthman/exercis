import SwiftUI
import SwiftData

#Preview {
    let session = WorkoutSession(date: Date())
    return HistoryCard(
        session: session,
        isExpanded: true,
        onTap: {},
        onDelete: {}
    )
    .background(Color.appBackground)
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}

private struct IdentifiableString: Identifiable {
    let id: String
}

struct HistoryCard: View {
    let session: WorkoutSession
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var chartExercise: IdentifiableString? = nil
    @State private var showEffortChart = false
    @AppStorage("useImperialUnits") private var imperial = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    HStack(spacing: 8) {
                        Text(dateText)
                            .font(.jost(.bold, size: 14))
                            .foregroundColor(.primary)
                        Text(timeText)
                            .font(.jost(.regular, size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    if !isExpanded {
                        Image(systemName: "chevron.right")
                            .font(.jost(.medium, size: 10))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.jost(.medium, size: 11))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(width: 44, height: 44, alignment: .trailing)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Delete workout")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, isExpanded ? 2 : 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Workout", systemImage: "trash")
                }
            }

            if isExpanded {
                expandedContent
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .sheet(item: $chartExercise) { item in
            ExerciseChartSheet(exerciseName: item.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEffortChart) {
            EffortChartSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Expanded

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let score = session.effortScore {
                Button {
                    showEffortChart = true
                } label: {
                    HStack(spacing: 4) {
                        Text("EFFORT")
                            .font(.jost(.medium, size: 10))
                            .kerning(1.5)
                            .foregroundColor(Color(.secondaryLabel))
                        Text("\(score)/10")
                            .font(.jost(.semibold, size: 10))
                            .kerning(1.5)
                            .foregroundColor(Color.historyAccent)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 0)
                .padding(.bottom, 4)
            }
            let sorted = session.exerciseLogs.sorted { $0.orderIndex < $1.orderIndex }
            ForEach(sorted) { exercise in
                exerciseBlock(exercise)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private func exerciseBlock(_ exercise: ExerciseLog) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            let displayName = ExerciseDef.find(name: exercise.name)?.displayName ?? exercise.name
            Button(displayName.uppercased()) {
                chartExercise = IdentifiableString(id: exercise.name)
            }
            .buttonStyle(.plain)
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundColor(Color.historyAccent)

            let compact = compactSets(exercise)
            if !compact.isEmpty {
                Text(compact)
                    .font(.jost(.regular, size: 14))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func compactSets(_ exercise: ExerciseLog) -> String {
        exercise.sets
            .sorted { $0.setNumber < $1.setNumber }
            .compactMap { s -> String? in
                guard s.reps > 0 || s.weight > 0 else { return nil }
                let w = s.weight > 0 ? displayWeight(s.weight, imperial: imperial) : "–"
                let r = s.reps > 0 ? "\(s.reps)" : "–"
                return "\(w)×\(r)"
            }
            .joined(separator: "  ")
    }

    private var dateText: String {
        let sv = Locale(identifier: "sv_SE")
        let weekday = session.date.formatted(.dateTime.weekday(.wide).locale(sv))
        let dayMonth = session.date.formatted(.dateTime.day().month(.wide).locale(sv))
        return "\(weekday.capitalized) \(dayMonth)"
    }

    private var timeText: String {
        session.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(Locale(identifier: "sv_SE")))
    }
}
