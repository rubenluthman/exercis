import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("selectedCardioTypes") private var selectedCardioTypesRaw = ""

    @State private var step = 1
    @State private var selectedProgramIds: Set<UUID> = []
    @State private var selectedCardioTypes: Set<String> = []

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
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("EXERCIS")
                .font(.jost(.black, size: 38))
                .kerning(6)
                .foregroundStyle(.primary)
                .padding(.top, 40)

            Text(step == 1
                 ? "Välj dina träningsprogram"
                 : "Vilka konditionsformer tränar du?")
                .font(.jost(.regular, size: 15))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
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

                    Button("BYGG EGET TRÄNINGSPROGRAM") {}
                        .font(.jost(.regular, size: 13))
                        .kerning(1.5)
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Spacer()
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
            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                if isSelected {
                    selectedProgramIds.remove(program.id)
                } else {
                    selectedProgramIds.insert(program.id)
                }
            } label: {
                ProgramCard(program: program, isSelected: isSelected, showCheckmark: true)
            }
            .buttonStyle(.plain)
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
                                        UISelectionFeedbackGenerator().selectionChanged()
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

            Spacer()
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
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? Color.workoutAccent : Color(.tertiaryLabel))

            Text(displayName(for: type))
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
                    .buttonStyle(FilledButtonStyle(accent: .homeAccent))
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
        selectedCardioTypesRaw = selectedCardioTypes.joined(separator: ",")
        onboardingCompleted = true
    }

    private func displayName(for type: CardioType) -> String {
        switch type {
        case .crosstrainer:       return "Crosstrainer"
        case .cyclingStationary:  return "Cykel"
        case .rowingMachine:      return "Roddmaskin"
        case .treadmillRun:       return "Löpband (löpning)"
        case .treadmillWalk:      return "Löpband (gång)"
        case .stairClimber:       return "Trappmaskin"
        case .skiErg:             return "Stakmaskin"
        case .assaultBike:        return "Assault Bike"
        case .running:            return "Löpning"
        case .walking:            return "Promenad"
        case .hiking:             return "Vandring"
        case .roadCycling:        return "Landsvägscykling"
        case .mountainBiking:     return "Terrängcykling"
        case .swimming:           return "Simning"
        case .crossCountrySkiing: return "Längdskidåkning"
        case .iceSkating:         return "Skridskoåkning"
        case .kayaking:           return "Kajak"
        case .canoeing:           return "Kanot"
        case .climbing:           return "Klättring"
        case .boxing:             return "Boxning"
        case .battleRopes:        return "Battle Ropes"
        case .sled:               return "Släde"
        case .rucking:            return "Rucking"
        case .jumpRope:           return "Hopprep"
        case .burpees:            return "Burpees"
        case .mountainClimbers:   return "Mountain Climbers"
        }
    }
}
