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
    @State private var showProfile = false
    @State private var showSettings = false
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]

    @AppStorage("profileName") private var profileName = ""

    private var profileInitials: String {
        let parts = profileName.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    private var profileImageFromDisk: UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile.jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    @ViewBuilder
    private var profileIcon: some View {
        if let image = profileImageFromDisk {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else if !profileInitials.isEmpty {
            Circle()
                .fill(Color(.secondarySystemFill))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(profileInitials)
                        .font(.jost(.semibold, size: 11))
                        .foregroundStyle(Color(.secondaryLabel))
                }
        } else {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 24))
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    private var lastSessionDate: Date? {
        let dates = ([workoutSessions.first?.date, cardioSessions.first?.date]).compactMap { $0 }
        return dates.max()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    showProfile = true
                } label: {
                    profileIcon
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profil")

                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
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
            .padding(.horizontal, 12)
            .padding(.top, 8)

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
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
