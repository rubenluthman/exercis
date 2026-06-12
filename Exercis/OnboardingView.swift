import SwiftUI
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.exercis", category: "SwiftData")

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("selectedCardioTypes") private var selectedCardioTypesRaw = ""
    @AppStorage("cardioTypeOrder")     private var cardioTypeOrderRaw = ""

    @State private var step = 1
    @State private var selectedProgramIds: Set<UUID> = []
    @State private var wantsRotation = false
    @State private var rotationIds: [String] = []
    @State private var rotationCurrentIndex = 0
    @State private var selectedCardioTypes: Set<String> = []
    @State private var editingProgram: WorkoutProgram? = nil
    @State private var healthKitDone = false

    private let letters = ["A", "B", "C", "D", "E", "F"]

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
            } else if step == 2 {
                rotationStep
            } else if step == 3 {
                cardioStep
            } else {
                healthStep
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

            Text(headerSubtitle)
                .font(.jost(.regular, size: 15))
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var headerSubtitle: String {
        switch step {
        case 1:  return String(localized: "Choose your training programs")
        case 2:  return String(localized: "Set up a program rotation")
        case 3:  return String(localized: "Which cardio types do you train?")
        default: return String(localized: "Connect Apple Health")
        }
    }

    // MARK: - Step 1: Programs

    private var programStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    programRow(programs.first { $0.name == "Full Body" })

                    HStack(spacing: 12) {
                        programRow(programs.first { $0.name == "Överkropp" })
                        programRow(programs.first { $0.name == "Underkropp" })
                    }

                    HStack(spacing: 8) {
                        programRow(programs.first { $0.name == "Push" })
                        programRow(programs.first { $0.name == "Pull" })
                        programRow(programs.first { $0.name == "Legs" })
                    }

                    programRow(programs.first { $0.name == "Bodyweight" })

                    if !selectedProgramIds.isEmpty {
                        rotationOptIn
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            bottomBar(
                primary: "FORTSÄTT",
                primaryEnabled: !selectedProgramIds.isEmpty,
                primaryAction: {
                    withAnimation { step = wantsRotation ? 2 : 3 }
                },
                skipAction: { withAnimation { step = 3 } }
            )
        }
    }

    private var rotationOptIn: some View {
        Button {
            Haptics.selection()
            wantsRotation.toggle()
            if !wantsRotation { rotationIds = [] }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: wantsRotation ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(wantsRotation ? Color.homeAccent : Color(.tertiaryLabel))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rotate programs (A/B)")
                        .font(.jost(.regular, size: 14))
                        .foregroundStyle(.primary)
                    Text("Automatically alternate between selected programs")
                        .font(.jost(.regular, size: 12))
                        .foregroundStyle(Color(.secondaryLabel))
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
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
                        rotationIds.removeAll { $0 == program.id.uuidString }
                        if selectedProgramIds.isEmpty { wantsRotation = false }
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
                .accessibilityLabel("Edit program")
                .padding(4)
            }
        }
    }

    // MARK: - Step 2: Rotation

    private var rotationStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    rotationSequenceSection
                    if rotationIds.count >= 2 {
                        ThinDivider()
                        rotationNextUpSection
                    }
                    ThinDivider()
                    rotationAddSection
                }
                .padding(.bottom, 40)
            }
            .softScrollEdge()

            bottomBar(
                primary: "FORTSÄTT",
                primaryEnabled: rotationIds.count >= 2,
                primaryAction: { withAnimation { step = 3 } },
                skipAction: {
                    rotationIds = []
                    withAnimation { step = 3 }
                }
            )
        }
    }

    private var rotationSequenceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            rotationSectionLabel("SEQUENCE")
                .padding(.horizontal, 24)

            if rotationIds.isEmpty {
                Text("Tap programs below to build the rotation order.")
                    .font(.jost(.regular, size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            } else {
                ForEach(Array(rotationIds.enumerated()), id: \.offset) { i, id in
                    let program = programs.first { $0.id.uuidString == id }
                    let letter = i < letters.count ? letters[i] : "\(i + 1)"
                    let accent = program.map { Color($0.colorName) } ?? Color(.secondaryLabel)
                    HStack(spacing: 12) {
                        Text(letter)
                            .font(.jost(.semibold, size: 12))
                            .kerning(1)
                            .foregroundStyle(accent)
                            .frame(width: 16)
                        Text(program?.name ?? "—")
                            .font(.jost(.regular, size: 15))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            removeFromRotation(at: i)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.jost(.medium, size: 11))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 24)
                    ThinDivider().padding(.leading, 56)
                }
            }
        }
    }

    private var rotationNextUpSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            rotationSectionLabel("NEXT UP")
                .padding(.horizontal, 24)
            Text("Which program is up first?")
                .font(.jost(.regular, size: 14))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            HStack(spacing: 8) {
                ForEach(Array(rotationIds.enumerated()), id: \.offset) { i, id in
                    let prog = programs.first { $0.id.uuidString == id }
                    let accent = prog.map { Color($0.colorName) } ?? Color(.secondaryLabel)
                    let isSelected = (rotationCurrentIndex % max(1, rotationIds.count)) == i
                    let letter = i < letters.count ? letters[i] : "\(i + 1)"
                    Button {
                        rotationCurrentIndex = i
                    } label: {
                        Text(letter)
                            .font(.jost(.semibold, size: 13))
                            .kerning(1)
                            .foregroundStyle(isSelected ? .white : accent)
                            .frame(width: 44, height: 36)
                            .background(isSelected ? accent : accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var rotationAddSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            rotationSectionLabel("ADD PROGRAMS")
                .padding(.horizontal, 24)

            let available = programs.filter {
                selectedProgramIds.contains($0.id) && !rotationIds.contains($0.id.uuidString)
            }
            if available.isEmpty {
                Text("All selected programs are in the rotation.")
                    .font(.jost(.regular, size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            } else {
                ForEach(available) { program in
                    Button {
                        guard rotationIds.count < 6 else { return }
                        rotationIds.append(program.id.uuidString)
                    } label: {
                        HStack {
                            Text(program.name)
                                .font(.jost(.regular, size: 15))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.jost(.medium, size: 13))
                                .foregroundStyle(Color(program.colorName))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.leading, 24)
                    }
                    .buttonStyle(.plain)
                    ThinDivider().padding(.leading, 24)
                }
            }
        }
    }

    private func removeFromRotation(at index: Int) {
        rotationIds.remove(at: index)
        if rotationIds.isEmpty {
            rotationCurrentIndex = 0
        } else if rotationCurrentIndex >= rotationIds.count {
            rotationCurrentIndex = 0
        }
    }

    private func rotationSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundStyle(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    // MARK: - Step 3: Cardio

    private var cardioStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(cardioGroups, id: \.title) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.title.uppercased())
                                .font(.jost(.medium, size: 12))
                                .kerning(1.5)
                                .foregroundStyle(Color(.secondaryLabel))
                                .padding(.horizontal, 24)

                            let pairs = stride(from: 0, to: group.types.count, by: 2).map {
                                Array(group.types[$0 ..< min($0 + 2, group.types.count)])
                            }
                            VStack(spacing: 8) {
                                ForEach(pairs, id: \.first!.rawValue) { pair in
                                    HStack(spacing: 8) {
                                        ForEach(pair, id: \.rawValue) { type in
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
                                        if pair.count == 1 { Spacer() }
                                    }
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
                primary: "NEXT",
                primaryEnabled: true,
                primaryAction: { step = 4 },
                skipAction: { step = 4 }
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

    // MARK: - Step 4: Apple Health

    private var healthStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.homeAccent)

                VStack(spacing: 8) {
                    Text("APPLE HEALTH")
                        .font(.jost(.bold, size: 17))
                        .kerning(2)
                        .foregroundStyle(.primary)

                    Text("Exercis saves your workouts to Apple Health and reads your body weight to calculate calorie burn.")
                        .font(.jost(.regular, size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 32)
            Spacer()

            bottomBar(
                primary: healthKitDone ? "GET STARTED" : "CONNECT HEALTH",
                primaryEnabled: true,
                primaryAction: {
                    if healthKitDone {
                        completeOnboarding()
                    } else {
                        Task {
                            await HealthKitManager.shared.requestAuthorization()
                            healthKitDone = true
                        }
                    }
                },
                skipAction: { completeOnboarding() }
            )
        }
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
        .background(.regularMaterial)
    }

    // MARK: - Completion

    private func completeOnboarding() {
        for program in programs {
            program.isOnTrainingPage = selectedProgramIds.contains(program.id)
        }

        if rotationIds.count >= 2 {
            let autoName = (0..<min(rotationIds.count, letters.count))
                .map { letters[$0] }
                .joined(separator: "/")
            let rotation = ProgramRotation(name: autoName, programIds: rotationIds)
            rotation.currentIndex = rotationCurrentIndex % rotationIds.count
            context.insert(rotation)
        }

        do { try context.save() } catch {
            #if DEBUG
            logger.error("context.save failed: \(error)")
            #endif
        }
        selectedCardioTypesRaw = CardioType.allCases
            .filter { selectedCardioTypes.contains($0.rawValue) }
            .map(\.rawValue)
            .joined(separator: ",")
        cardioTypeOrderRaw = ""
        onboardingCompleted = true
    }

}
