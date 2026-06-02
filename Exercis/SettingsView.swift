import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("weightUnit")              private var weightUnit = "kg"
    @AppStorage("distanceUnit")            private var distanceUnit = "km"
    @AppStorage("healthKitSyncEnabled")    private var healthKitSyncEnabled = true
    @AppStorage("healthKitWeightEnabled")  private var healthKitWeightEnabled = true
    @AppStorage("lockEnabled")             private var lockEnabled = true

    @State private var exportItems: [Any] = []
    @State private var showExportSheet = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Träning") {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(Color.homeAccent)
                            .frame(width: 28)
                        Text("Program")
                            .font(.jost(.regular, size: 16))
                        Spacer()
                        Text("Kommer snart")
                            .font(.jost(.regular, size: 14))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Section {
                    Toggle(isOn: $healthKitSyncEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spara pass till Hälsa")
                                    .font(.jost(.regular, size: 16))
                                Text("Dina pass sparas i Apple Hälsa så att de visas i Aktivitet och Fitness.")
                                    .font(.jost(.regular, size: 12))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                    .tint(Color.homeAccent)

                    Toggle(isOn: $healthKitWeightEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(Color(.secondaryLabel))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hämta kroppsvikt från Hälsa")
                                    .font(.jost(.regular, size: 16))
                                Text("Appen läser ditt senaste registrerade värde och använder det enbart för att beräkna kaloriförbrukning.")
                                    .font(.jost(.regular, size: 12))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                    .tint(Color.homeAccent)
                } header: {
                    Text("Hälsa")
                }

                Section("Sekretess") {
                    Toggle(isOn: $lockEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .foregroundStyle(Color(.secondaryLabel))
                                .frame(width: 28)
                            Text("Face ID-lås")
                                .font(.jost(.regular, size: 16))
                        }
                    }
                    .tint(Color.homeAccent)
                }

                Section("Data") {
                    Button {
                        exportItems = buildExportItems()
                        showExportSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.historyAccent)
                                .frame(width: 28)
                            Text("Exportera träningsdata")
                                .font(.jost(.regular, size: 16))
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Om") {
                    HStack {
                        Text("Version")
                            .font(.jost(.regular, size: 16))
                        Spacer()
                        Text(appVersion)
                            .font(.jost(.regular, size: 16))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
            .navigationTitle("Inställningar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klar") { dismiss() }
                        .font(.jost(.semibold, size: 16))
                        .foregroundStyle(Color.historyAccent)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if !exportItems.isEmpty {
                    ShareSheet(items: exportItems)
                }
            }
        }
    }

    // MARK: - CSV export

    private func buildExportItems() -> [Any] {
        let workoutSessions = (try? context.fetch(
            FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)])
        )) ?? []
        let cardioSessions = (try? context.fetch(
            FetchDescriptor<CardioSession>(sortBy: [SortDescriptor(\.date)])
        )) ?? []

        var items: [Any] = []

        if !workoutSessions.isEmpty {
            if let url = writeCSV(filename: "styrka.csv", content: strengthCSV(workoutSessions)) {
                items.append(url)
            }
        }
        if !cardioSessions.isEmpty {
            if let url = writeCSV(filename: "kondition.csv", content: cardioCSV(cardioSessions)) {
                items.append(url)
            }
        }
        return items
    }

    private func strengthCSV(_ sessions: [WorkoutSession]) -> String {
        var rows = ["datum,program,övning,set,kg,reps,e1RM"]
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        for session in sessions {
            let date = fmt.string(from: session.date)
            let program = session.programName ?? ""
            for log in session.exerciseLogs.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                for set in log.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let e1rm = set.reps > 0 ? set.weight * (1 + Double(set.reps) / 30) : set.weight
                    rows.append("\(date),\(program),\(log.name),\(set.setNumber),\(formatWeight(set.weight)),\(set.reps),\(String(format: "%.1f", e1rm))")
                }
            }
        }
        return rows.joined(separator: "\n")
    }

    private func cardioCSV(_ sessions: [CardioSession]) -> String {
        var rows = ["datum,typ,minuter,km,ansträngning"]
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        for session in sessions {
            let date = fmt.string(from: session.date)
            let type_ = CardioType(rawValue: session.cardioType)?.displayName ?? session.cardioType
            let km = session.distanceKm.map { formatWeight($0) } ?? ""
            let effort = session.effortScore.map { "\($0)" } ?? ""
            rows.append("\(date),\(type_),\(formatWeight(session.durationMinutes)),\(km),\(effort)")
        }
        return rows.joined(separator: "\n")
    }

    private func writeCSV(filename: String, content: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
