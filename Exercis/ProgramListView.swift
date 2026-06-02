import SwiftUI
import SwiftData

struct ProgramListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @AppStorage("hasDraft") private var hasDraft = false
    @State private var activeProgram: WorkoutProgram? = nil
    @State private var editingProgram: WorkoutProgram? = nil
    @State private var showNewProgram = false
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
                                            .font(.jost(.semibold, size: 11))
                                            .foregroundStyle(Color(.secondaryLabel))
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Kasta utkast")
                                } else {
                                    Button {
                                        editingProgram = program
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.jost(.medium, size: 13))
                                            .foregroundStyle(Color(.tertiaryLabel))
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Redigera \(program.name)")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showNewProgram = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.jost(.semibold, size: 13))
                            Text("NYTT PROGRAM")
                                .font(.jost(.semibold, size: 12))
                                .kerning(1.5)
                        }
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .softScrollEdge()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editingProgram) { program in
            ProgramEditorView(program: program)
        }
        .sheet(isPresented: $showNewProgram) {
            ProgramEditorView(program: nil)
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
        Text("EXERCIS")
            .font(.jost(.black, size: 38))
            .kerning(6)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
    }
}
