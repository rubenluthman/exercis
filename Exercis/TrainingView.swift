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
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                VStack(spacing: 24) {
                    if !trainingPrograms.isEmpty {
                        programSection
                    }
                    if !selectedCardioTypes.isEmpty {
                        cardioSection
                    }
                    if trainingPrograms.isEmpty && selectedCardioTypes.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 24)
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
        .sheet(item: $activeCardioType) { type in
            CardioView(initialType: type)
        }
        .alert("Ta bort pågående utkast?", isPresented: $showDiscardAlert) {
            Button("Ta bort", role: .destructive) {
                UserDefaults.standard.saveDraft(nil)
                hasDraft = false
                activeProgram = pendingProgram
                pendingProgram = nil
            }
            Button("Avbryt", role: .cancel) { pendingProgram = nil }
        }
    }

    private var headerRow: some View {
        Text("TRÄNING")
            .font(.jost(.bold, size: 17))
            .kerning(2)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
    }

    private var programSection: some View {
        VStack(spacing: 8) {
            sectionLabel("STYRKA")
            ForEach(trainingPrograms) { program in
                let isDraft = hasDraft && UserDefaults.standard.loadDraft()?.programId == program.id.uuidString
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
                        if isDraft {
                            Button {
                                UserDefaults.standard.saveDraft(nil)
                                hasDraft = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.jost(.semibold, size: 11))
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Kasta utkast")
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cardioSection: some View {
        VStack(spacing: 8) {
            sectionLabel("KONDITION")
            ForEach(selectedCardioTypes, id: \.self) { type in
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
                            Text("FORTSÄTT")
                                .font(.jost(.medium, size: 10))
                                .kerning(1.5)
                                .foregroundStyle(Color.workoutAccent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Inga träningspass konfigurerade")
                .font(.jost(.regular, size: 15))
                .foregroundStyle(Color(.secondaryLabel))
            Text("Lägg till program och konditionsformer i Inställningar")
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
    }
}
