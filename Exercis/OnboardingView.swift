import SwiftUI
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.exercis", category: "SwiftData")

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("selectedCardioTypes") private var selectedCardioTypesRaw = ""

    @State private var step = 1
    @State private var selectedProgramIds: Set<UUID> = []
    @State private var selectedCardioTypes: Set<String> = []
    @State private var editingProgram: WorkoutProgram? = nil

    // Cardio groups for step 2
    private let cardioGroups: [(title: String, types: [CardioType])] = [
        ("Maskiner", [.crosstrainer, .cyclingStationary, .rowingMachine, .treadmillRun,
                       .treadmillWalk, .stairClimber, .skiErg, .assaultBike]),
        ("Utomhus", [.running, .walking, .hiking, .roadCycling, .mountainBiking, .swimming]),
        ("Nordiska", [.crossCountrySkiing, .iceSkating]),
        ("Vatten", [.kayaking, .canoeing]),
        ("Övrigt", [.climbing, .boxing, .battleRopes, .sled, .rucking]),
        ("Calisthenics", [.jumpRope, .burpees, .mountainClimbers])
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            if step == 1 {
                programStep
            } else {
                cardioStep
            }
        }
        .animation(.easeInOut(duration: 0.22), value: step)
        .onAppear {
            seedDefaultProgramsIfNeeded(context: context)
        }
        .sheet(item: $editingProgram) { program in
            ProgramEditorView(program: program)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("EXERCIS")
                .font(.jost(.black, size: 38))
                .kerning(6)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)

            Text(step == 1
                 ? "Välj dina träningsprogram"
                 : "Vilka konditionsformer tränar du?")
                .font(.jost(.regular, size: 15))
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 1: Programs

    private var programStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Full Body — full width
                    programRow(programs.first { $0.name == "Full Body" })

                    // Överkropp + Underkropp — 2 columns
                    HStack(spacing: 12) {
                        programRow(programs.first { $0.name == "Överkropp" })
                        programRow(programs.first { $0.name == "Underkropp" })
                    }

                    // Push + Pull + Legs — 3 columns
                    HStack(spacing: 8) {
                        programRow(programs.first { $0.name == "Push" })
                        programRow(programs.first { $0.name == "Pull" })
                        programRow(programs.first { $0.name == "Legs" })
                    }

                    // Bodyweight — full width
                    programRow(programs.first { $0.name == "Bodyweight" })

                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            bottomBar(
                primary: "FORTSÄTT",
                primaryEnabled: !selectedProgramIds.isEmpty,
                primaryAction: { withAnimation { step = 2 } },
                skipAction: { withAnimation { step = 2 } }
            )
        }
    }

    @ViewBuilder
    private func programRow(_ program: WorkoutProgram?) -> some View {
        if let program {
            let isSelected = selectedProgramIds.contains(program.id)
            ZStack(alignment: .topTrailing) {
                Button {
                    Haptics.selection()
                    if isSelected {
                        selectedProgramIds.remove(program.id)
                    } else {
                        selectedProgramIds.insert(program.id)
                    }
                } label: {
                    ProgramCard(program: program, isSelected: isSelected, showCheckmark: true)
                }
                .buttonStyle(.plain)

                Button {
                    editingProgram = program
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(program.colorName))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .padding(4)
            }
        }
    }

    // MARK: - Step 2: Cardio

    private var cardioStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(cardioGroups, id: \.title) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.title.uppercased())
                                .font(.jost(.medium, size: 10))
                                .kerning(1.5)
                                .foregroundStyle(Color(.secondaryLabel))
                                .padding(.horizontal, 24)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                      spacing: 8) {
                                ForEach(group.types, id: \.rawValue) { type in
                                    let isSelected = selectedCardioTypes.contains(type.rawValue)
                                    Button {
                                        Haptics.selection()
                                        if isSelected {
                                            selectedCardioTypes.remove(type.rawValue)
                                        } else {
                                            selectedCardioTypes.insert(type.rawValue)
                                        }
                                    } label: {
                                        cardioTypeRow(type: type, isSelected: isSelected)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.bottom, 24)
            }

            bottomBar(
                primary: "KOM IGÅNG",
                primaryEnabled: true,
                primaryAction: { completeOnboarding() },
                skipAction: { completeOnboarding() }
            )
        }
    }

    private func cardioTypeRow(type: CardioType, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.jost(.regular, size: 16))
                .foregroundStyle(isSelected ? Color.workoutAccent : Color(.tertiaryLabel))

            Text(type.displayName)
                .font(.jost(.regular, size: 14))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Bottom bar

    private func bottomBar(primary: String, primaryEnabled: Bool,
                            primaryAction: @escaping () -> Void,
                            skipAction: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            ThinDivider()
            HStack(spacing: 16) {
                Button("HOPPA ÖVER") { skipAction() }
                    .font(.jost(.regular, size: 13))
                    .kerning(1.5)
                    .foregroundStyle(Color(.secondaryLabel))

                Button(primary) { primaryAction() }
                    .primaryButtonStyle(accent: .homeAccent)
                    .opacity(primaryEnabled ? 1 : 0.4)
                    .disabled(!primaryEnabled)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground)
    }

    // MARK: - Completion

    private func completeOnboarding() {
        for program in programs {
            program.isOnTrainingPage = selectedProgramIds.contains(program.id)
        }
        do { try context.save() } catch {
            #if DEBUG
            logger.error("context.save failed: \(error)")
            #endif
        }
        selectedCardioTypesRaw = selectedCardioTypes.joined(separator: ",")
        onboardingCompleted = true
    }

}
