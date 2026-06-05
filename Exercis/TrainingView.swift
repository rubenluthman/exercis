import SwiftUI
import SwiftData

struct TrainingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @AppStorage("hasDraft") private var hasDraft = false
    @AppStorage("hasCardioDraft") private var hasCardioDraft = false
    @AppStorage("selectedCardioTypes") private var selectedCardioTypesRaw = ""
    @State private var activeProgram: WorkoutProgram? = nil
    @State private var activeCardioType: CardioType? = nil
    @State private var showDiscardAlert = false
    @State private var pendingProgram: WorkoutProgram? = nil

    private var trainingPrograms: [WorkoutProgram] {
        programs.filter { $0.isOnTrainingPage }
    }

    private var selectedCardioTypes: [CardioType] {
        selectedCardioTypesRaw
            .split(separator: ",")
            .compactMap { CardioType(rawValue: String($0)) }
            .sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                VStack(spacing: 0) {
                    if !trainingPrograms.isEmpty {
                        programSection
                        ThinDivider()
                    }
                    if !selectedCardioTypes.isEmpty {
                        cardioSection
                    }
                    if trainingPrograms.isEmpty && selectedCardioTypes.isEmpty {
                        emptyState
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .softScrollEdge()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $activeProgram) { program in
            StrengthView(program: program)
                .enableSwipeBack()
        }
        .navigationDestination(item: $activeCardioType) { type in
            CardioView(type: type)
                .enableSwipeBack()
        }
        .alert("Discard active draft?", isPresented: $showDiscardAlert) {
            Button("Delete", role: .destructive) {
                UserDefaults.standard.saveDraft(nil)
                hasDraft = false
                activeProgram = pendingProgram
                pendingProgram = nil
            }
            Button("Cancel", role: .cancel) { pendingProgram = nil }
        }
    }

    private var headerRow: some View {
        Text("TRAINING")
            .font(.jost(.bold, size: 17))
            .kerning(2)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
    }

    private var programSection: some View {
        VStack(spacing: 0) {
            sectionLabel("STRENGTH")
                .padding(.horizontal, 24)
            ThinDivider()
            ForEach(trainingPrograms) { program in
                let isDraft = hasDraft && UserDefaults.standard.loadDraft()?.programId == program.id.uuidString
                HStack(spacing: 0) {
                    Button {
                        if isDraft {
                            activeProgram = program
                        } else if hasDraft {
                            pendingProgram = program
                            showDiscardAlert = true
                        } else {
                            activeProgram = program
                        }
                    } label: {
                        HStack(spacing: 0) {
                            ProgramCard(program: program)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                            if !isDraft {
                                Image(systemName: "chevron.right")
                                    .font(.jost(.medium, size: 10))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .padding(.trailing, 24)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if isDraft {
                        VStack(spacing: 2) {
                            Text("CONTINUE")
                                .font(.jost(.semibold, size: 10))
                                .kerning(1.5)
                                .foregroundStyle(Color(program.colorName))
                            Button {
                                UserDefaults.standard.saveDraft(nil)
                                hasDraft = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.jost(.medium, size: 11))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Discard draft")
                        }
                        .padding(.trailing, 8)
                    }
                }
                ThinDivider()
            }
        }
    }

    private var cardioSection: some View {
        VStack(spacing: 0) {
            sectionLabel("CARDIO")
            ThinDivider()
            ForEach(Array(selectedCardioTypes.enumerated()), id: \.element) { _, type in
                let isDraft = hasCardioDraft && UserDefaults.standard.string(forKey: "cardioDraftType") == type.rawValue
                Button {
                    activeCardioType = type
                } label: {
                    HStack {
                        Text(type.displayName.uppercased())
                            .font(.jost(.semibold, size: 13))
                            .kerning(1.5)
                            .foregroundStyle(Color.workoutAccent)
                        Spacer()
                        if isDraft {
                            Text("CONTINUE")
                                .font(.jost(.medium, size: 10))
                                .kerning(1.5)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        Image(systemName: "chevron.right")
                            .font(.jost(.medium, size: 10))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                ThinDivider()
            }
        }
        .padding(.horizontal, 0)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No training configured")
                .font(.jost(.regular, size: 15))
                .foregroundStyle(Color(.secondaryLabel))
            Text("Add programs and cardio types in Settings")
                .font(.jost(.regular, size: 13))
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.jost(.medium, size: 10))
            .kerning(1.5)
            .foregroundStyle(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}
