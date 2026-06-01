import SwiftUI
import SwiftData

struct ProgramListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @AppStorage("hasDraft") private var hasDraft = false
    @AppStorage("lockEnabled") private var lockEnabled = true
    @State private var activeProgram: WorkoutProgram? = nil
    @State private var showSettings = false
    @State private var showDiscardAlert = false
    @State private var draftProgram: WorkoutProgram? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                LazyVStack(spacing: 12) {
                    ForEach(programs) { program in
                        let isDraft = hasDraft && UserDefaults.standard.loadDraft()?.programId == program.id.uuidString

                        Button {
                            if isDraft {
                                activeProgram = program
                            } else if hasDraft {
                                draftProgram = program
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
                                            .font(.system(size: 11, weight: .semibold))
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
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .softScrollEdge()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $activeProgram) { program in
            StrengthView(program: program)
        }
        .alert("Ta bort pågående utkast?", isPresented: $showDiscardAlert) {
            Button("Ta bort", role: .destructive) {
                UserDefaults.standard.saveDraft(nil)
                hasDraft = false
                activeProgram = draftProgram
                draftProgram = nil
            }
            Button("Avbryt", role: .cancel) { draftProgram = nil }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("EXERCIS")
                .font(.jost(.black, size: 38))
                .kerning(6)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Inställningar")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}
