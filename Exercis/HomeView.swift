import SwiftUI
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, CardioSession.self, configurations: config)
    let session = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
    container.mainContext.insert(session)
    return NavigationStack {
        HomeView()
            .modelContainer(container)
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasDraft") private var hasDraft = false
    @AppStorage("hasCardioDraft") private var hasCardioDraft = false
    @State private var showDiscardWorkoutAlert = false
    @State private var showDiscardCardioAlert = false
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]

    private var lastSessionDate: Date? {
        let dates = ([workoutSessions.first?.date, cardioSessions.first?.date]).compactMap { $0 }
        return dates.max()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                Text("EXERCIS")
                    .font(.jost(.black, size: 38))
                    .kerning(6)
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    if hasDraft {
                        ZStack {
                            NavigationLink(value: AppScreen.workout) {
                                Text("FORTSÄTT STYRKA")
                            }
                            .buttonStyle(FilledButtonStyle(accent: Color.homeAccent))

                            HStack {
                                Spacer()
                                Button(action: { showDiscardWorkoutAlert = true }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(height: 50)
                                        .padding(.trailing, 16)
                                }
                                .accessibilityLabel("Kasta utkast")
                            }
                        }
                    } else {
                        NavigationLink(value: AppScreen.workout) {
                            Text("STYRKA")
                        }
                        .buttonStyle(FilledButtonStyle(accent: Color.homeAccent))
                    }

                    if hasCardioDraft {
                        ZStack {
                            NavigationLink(value: AppScreen.cardio) {
                                Text("FORTSÄTT KONDITION")
                            }
                            .buttonStyle(FilledButtonStyle(accent: Color.workoutAccent))

                            HStack {
                                Spacer()
                                Button(action: { showDiscardCardioAlert = true }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(height: 50)
                                        .padding(.trailing, 16)
                                }
                                .accessibilityLabel("Kasta utkast")
                            }
                        }
                    } else {
                        NavigationLink(value: AppScreen.cardio) {
                            Text("KONDITION")
                        }
                        .buttonStyle(FilledButtonStyle(accent: Color.workoutAccent))
                    }

                    NavigationLink(value: AppScreen.history) {
                        Text("HISTORIK")
                    }
                    .buttonStyle(OutlineButtonStyle(accent: Color.historyAccent))
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)

                NavigationLink(value: AppScreen.history) {
                    Text(lastSessionDate.map {
                        $0.formatted(.dateTime.weekday(.abbreviated).day().month(.wide).locale(Locale(identifier: "sv_SE"))).uppercased()
                    } ?? " ")
                        .font(.jost(.regular, size: 12))
                        .kerning(1)
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.top, 24)
                        .opacity(lastSessionDate != nil ? 1 : 0)
                }
                .disabled(lastSessionDate == nil)

                Spacer()
            }
        }
        .onAppear { migrateExerciseNames(context: context) }
        .alert("Ta bort påbörjat pass?", isPresented: $showDiscardWorkoutAlert) {
            Button("Ta bort", role: .destructive) { discardWorkoutDraft() }
            Button("Avbryt", role: .cancel) {}
        }
        .alert("Ta bort påbörjat konditionspass?", isPresented: $showDiscardCardioAlert) {
            Button("Ta bort", role: .destructive) { discardCardioDraft() }
            Button("Avbryt", role: .cancel) {}
        }
    }

    private func discardWorkoutDraft() {
        UserDefaults.standard.saveDraft(nil)
        hasDraft = false
    }

    private func discardCardioDraft() {
        UserDefaults.standard.removeObject(forKey: "cardioDraftType")
        UserDefaults.standard.removeObject(forKey: "cardioDraftMinutes")
        UserDefaults.standard.removeObject(forKey: "cardioDraftDistance")
        hasCardioDraft = false
    }
}
