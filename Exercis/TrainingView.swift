import SwiftUI
import SwiftData

struct StrengthLaunch: Identifiable, Hashable {
    let id = UUID()
    let program: WorkoutProgram
    let rotationId: UUID?

    static func == (lhs: StrengthLaunch, rhs: StrengthLaunch) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TrainingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @Query(sort: \ProgramRotation.sortIndex) private var rotations: [ProgramRotation]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]
    @AppStorage("hasDraft") private var hasDraft = false
    @AppStorage("hasCardioDraft") private var hasCardioDraft = false
    @AppStorage("selectedCardioTypes") private var selectedCardioTypesRaw = ""
    @AppStorage("cardioTypeOrder")     private var cardioTypeOrderRaw = ""
    @State private var activeLaunch: StrengthLaunch? = nil
    @State private var activeCardioType: CardioType? = nil
    @State private var pendingLaunch: StrengthLaunch? = nil
    @State private var showDiscardAlert = false
    @State private var showDiscardStrengthAlert = false
    @State private var showDiscardCardioAlert = false
    @State private var cardioTypeToDiscard: CardioType? = nil

    private var trainingPrograms: [WorkoutProgram] {
        programs.filter { $0.isOnTrainingPage }
    }

    private var selectedCardioTypes: [CardioType] {
        let selected = Set(selectedCardioTypesRaw.split(separator: ",").map(String.init))
        let order: [CardioType] = cardioTypeOrderRaw.isEmpty
            ? CardioType.allCases
            : cardioTypeOrderRaw.split(separator: ",").compactMap { CardioType(rawValue: String($0)) }
        return order.filter { selected.contains($0.rawValue) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                VStack(spacing: 0) {
                    let hasStrength = !rotations.isEmpty || !trainingPrograms.isEmpty
                    if hasStrength {
                        strengthSection
                        ThinDivider()
                    }
                    if !selectedCardioTypes.isEmpty {
                        cardioSection
                    }
                    if !hasStrength && selectedCardioTypes.isEmpty {
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
        .navigationDestination(item: $activeLaunch) { launch in
            StrengthView(program: launch.program, rotationId: launch.rotationId)
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
                activeLaunch = pendingLaunch
                pendingLaunch = nil
            }
            Button("Cancel", role: .cancel) { pendingLaunch = nil }
        }
        .alert("Discard active draft?", isPresented: $showDiscardStrengthAlert) {
            Button("Delete", role: .destructive) {
                UserDefaults.standard.saveDraft(nil)
                hasDraft = false
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Discard active draft?", isPresented: $showDiscardCardioAlert) {
            Button("Delete", role: .destructive) {
                if let type = cardioTypeToDiscard {
                    UserDefaults.standard.removeObject(forKey: "cardioDraftType")
                    UserDefaults.standard.removeObject(forKey: "cardioDraftStartTime_\(type.rawValue)")
                    UserDefaults.standard.removeObject(forKey: "cardioDraftDistance_\(type.rawValue)")
                }
                hasCardioDraft = false
                cardioTypeToDiscard = nil
            }
            Button("Cancel", role: .cancel) { cardioTypeToDiscard = nil }
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

    private var strengthSection: some View {
        VStack(spacing: 0) {
            sectionLabel(String(localized: "STRENGTH"))
                .padding(.horizontal, 24)

            ForEach(rotations) { rotation in
                rotationRow(rotation)
            }

            ForEach(trainingPrograms) { program in
                let draftProgramId = UserDefaults.standard.loadDraft()?.programId
                let isDraft = hasDraft && (draftProgramId == program.id.uuidString || (draftProgramId == nil && trainingPrograms.first?.id == program.id))
                HStack(spacing: 0) {
                    Button {
                        let launch = StrengthLaunch(program: program, rotationId: nil)
                        if isDraft {
                            activeLaunch = launch
                        } else if hasDraft {
                            pendingLaunch = launch
                            showDiscardAlert = true
                        } else {
                            activeLaunch = launch
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
                        Button {
                            showDiscardStrengthAlert = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.jost(.medium, size: 11))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Discard draft")
                        .padding(.trailing, 8)
                    }
                }
                ThinDivider()
            }
        }
    }

    @ViewBuilder
    private func rotationRow(_ rotation: ProgramRotation) -> some View {
        let nextId = rotation.programIds.isEmpty ? nil : rotation.programIds[rotation.nextIndex]
        let nextProgram = programs.first { $0.id.uuidString == nextId }
        let draftProgramId = UserDefaults.standard.loadDraft()?.programId
        let isDraft = hasDraft && nextProgram.map { draftProgramId == $0.id.uuidString } ?? false

        HStack(spacing: 0) {
            Button {
                guard let prog = nextProgram else { return }
                let launch = StrengthLaunch(program: prog, rotationId: rotation.id)
                if isDraft {
                    activeLaunch = launch
                } else if hasDraft {
                    pendingLaunch = launch
                    showDiscardAlert = true
                } else {
                    activeLaunch = launch
                }
            } label: {
                HStack(spacing: 0) {
                    RotationCard(rotation: rotation, allPrograms: programs, hasDraft: isDraft)
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
            .opacity(nextProgram == nil ? 0.4 : 1)
            .disabled(nextProgram == nil)

            if isDraft {
                Button {
                    showDiscardStrengthAlert = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.jost(.medium, size: 11))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Discard draft")
                .padding(.trailing, 8)
            }
        }
        ThinDivider()
    }

    private var cardioSection: some View {
        VStack(spacing: 0) {
            sectionLabel(String(localized: "CARDIO"))
                .padding(.horizontal, 24)
            ForEach(Array(selectedCardioTypes.enumerated()), id: \.element) { _, type in
                let isDraft = hasCardioDraft && UserDefaults.standard.string(forKey: "cardioDraftType") == type.rawValue
                let lastDuration = cardioSessions.first(where: { $0.cardioType == type.rawValue })?.durationMinutes
                HStack(spacing: 0) {
                    Button {
                        activeCardioType = type
                    } label: {
                        HStack(spacing: 0) {
                            CardioTypeCard(type: type, lastDurationMinutes: lastDuration)
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
                        Button {
                            cardioTypeToDiscard = type
                            showDiscardCardioAlert = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.jost(.medium, size: 11))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Discard cardio draft")
                        .padding(.trailing, 8)
                    }
                }
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
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundStyle(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}
