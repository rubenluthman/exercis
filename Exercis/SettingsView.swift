import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("weightUnit")              private var weightUnit = "kg"
    @AppStorage("distanceUnit")            private var distanceUnit = "km"
    @AppStorage("restTimerSeconds")        private var restTimerSeconds = 90
    @AppStorage("healthKitSyncEnabled")    private var healthKitSyncEnabled = true
    @AppStorage("healthKitWeightEnabled")  private var healthKitWeightEnabled = true
    @AppStorage("lockEnabled")             private var lockEnabled = true

    @State private var exportItems: [Any] = []
    @State private var showExportSheet = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ThinDivider().padding(.top, 8)

            ScrollView {
                VStack(spacing: 0) {
                    sectionBlock {
                        sectionLabel("TRÄNING")
                        timerRow
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("HÄLSA")
                        toggleRow(
                            title: "SPARA PASS TILL HÄLSA",
                            description: "Dina pass sparas i Apple Hälsa och visas i Aktivitet och Fitness.",
                            isOn: $healthKitSyncEnabled
                        )
                        ThinDivider().padding(.leading, 24)
                        toggleRow(
                            title: "HÄMTA KROPPSVIKT FRÅN HÄLSA",
                            description: "Appen läser ditt senaste registrerade värde och använder det enbart för att beräkna kaloriförbrukning.",
                            isOn: $healthKitWeightEnabled
                        )
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("SEKRETESS")
                        toggleRow(
                            title: "FACE ID-LÅS",
                            description: nil,
                            isOn: $lockEnabled
                        )
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("DATA")
                        actionRow(
                            title: "EXPORTERA TRÄNINGSDATA",
                            systemImage: "square.and.arrow.up"
                        ) {
                            exportItems = buildExportItems()
                            showExportSheet = true
                        }
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("OM")
                        HStack {
                            Text("VERSION")
                                .font(.jost(.semibold, size: 12))
                                .kerning(1.5)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(appVersion)
                                .font(.jost(.regular, size: 13))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }

                    ThinDivider()
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if !exportItems.isEmpty {
                ShareSheet(items: exportItems)
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("INSTÄLLNINGAR")
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundStyle(.primary)
            Spacer()
            Button("KLAR") { dismiss() }
                .font(.jost(.semibold, size: 13))
                .kerning(1.5)
                .foregroundStyle(Color.historyAccent)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Building blocks

    private func sectionBlock<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.jost(.medium, size: 10))
            .kerning(1.5)
            .foregroundStyle(Color(.secondaryLabel))
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func toggleRow(title: String, description: String?, isOn: Binding<Bool>) -> some View {
        HStack(alignment: description != nil ? .top : .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.jost(.semibold, size: 12))
                    .kerning(1.5)
                    .foregroundStyle(.primary)
                if let description {
                    Text(description)
                        .font(.jost(.regular, size: 12))
                        .foregroundStyle(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.homeAccent)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func actionRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.jost(.medium, size: 14))
                Text(title)
                    .font(.jost(.semibold, size: 12))
                    .kerning(1.5)
                Spacer()
            }
            .foregroundStyle(Color.historyAccent)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer row

    private var timerRow: some View {
        HStack {
            Text("VILOTIMER")
                .font(.jost(.semibold, size: 12))
                .kerning(1.5)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 0) {
                ForEach([30, 60, 90, 120], id: \.self) { secs in
                    Button {
                        Haptics.selection()
                        restTimerSeconds = secs
                    } label: {
                        Text(secs < 120 ? "\(secs)s" : "2 min")
                            .font(.jost(.semibold, size: 11))
                            .kerning(1)
                            .foregroundStyle(restTimerSeconds == secs ? .white : Color(.secondaryLabel))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                restTimerSeconds == secs
                                    ? Color.homeAccent
                                    : Color(.secondarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    if secs != 120 {
                        Spacer().frame(width: 4)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
