import SwiftUI
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.exercis", category: "SwiftData")

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.sortIndex) private var programs: [WorkoutProgram]
    @Query(sort: \ProgramRotation.sortIndex) private var rotations: [ProgramRotation]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    @AppStorage("onboardingCompleted")     private var onboardingCompleted = true
    @AppStorage("restTimerSeconds")        private var restTimerSeconds = 90
    @AppStorage("useImperialUnits")        private var useImperialUnits = false
    @AppStorage("dateLocaleIdentifier")    private var dateLocaleIdentifier = ""
    @AppStorage("healthKitSyncEnabled")    private var healthKitSyncEnabled = true
    @AppStorage("healthKitWeightEnabled")  private var healthKitWeightEnabled = true
    @AppStorage("lockEnabled")             private var lockEnabled = true
    @AppStorage("selectedCardioTypes")     private var selectedCardioTypesRaw = ""
    @AppStorage("cardioTypeOrder")         private var cardioTypeOrderRaw = ""
    @AppStorage("bodyLimitations")         private var bodyLimitationsRaw = ""
    @AppStorage("reminderEnabled")         private var reminderEnabled = false
    @AppStorage("reminderWeekdays")        private var reminderWeekdaysRaw = ""
    @AppStorage("reminderHour")            private var reminderHour = 17
    @AppStorage("reminderMinute")          private var reminderMinute = 0

    @State private var exportItems: [Any] = []
    @State private var showExportSheet = false
    @State private var editingProgram: WorkoutProgram? = nil
    @State private var showNewProgram = false
    @State private var editingRotation: ProgramRotation? = nil
    @State private var showNewRotation = false
    @State private var showWhatsNew = false
    @State private var showProgramReorder = false
    @State private var showCardioReorder = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var selectedTypes: Set<String> {
        Set(selectedCardioTypesRaw.split(separator: ",").map(String.init))
    }

    private var orderedAllCardioTypes: [CardioType] {
        if cardioTypeOrderRaw.isEmpty {
            return CardioType.allCases
        }
        let stored = cardioTypeOrderRaw.split(separator: ",").compactMap { CardioType(rawValue: String($0)) }
        let storedSet = Set(stored.map(\.rawValue))
        let missing = CardioType.allCases.filter { !storedSet.contains($0.rawValue) }
        return stored + missing
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ThinDivider().padding(.top, 8)

            ScrollView {
                VStack(spacing: 0) {
                    sectionBlock {
                        HStack(alignment: .bottom) {
                            sectionLabel("STRENGTH PROGRAMS")
                            Spacer()
                            if programs.count >= 2 {
                                Button {
                                    Haptics.selection()
                                    showProgramReorder = true
                                } label: {
                                    Text("REORDER")
                                        .font(.jost(.medium, size: 12))
                                        .kerning(1.5)
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 24)
                                .padding(.bottom, 8)
                            }
                        }
                        ForEach(programs) { program in
                            programRow(program)
                            if program.id != programs.last?.id {
                                ThinDivider().padding(.leading, 24)
                            }
                        }
                        Button {
                            showNewProgram = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.jost(.semibold, size: 15))
                                Text("NEW PROGRAM")
                                    .font(.jost(.semibold, size: 14))
                                    .kerning(1.5)
                            }
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("ROTATIONS")
                        if rotations.isEmpty {
                            Text("A rotation lets you alternate between programs automatically — e.g. A/B/A.")
                                .font(.jost(.regular, size: 14))
                                .foregroundStyle(Color(.secondaryLabel))
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                                .padding(.bottom, 12)
                        } else {
                            ForEach(rotations) { rotation in
                                rotationRow(rotation)
                                if rotation.id != rotations.last?.id {
                                    ThinDivider().padding(.leading, 24)
                                }
                            }
                        }
                        Button {
                            showNewRotation = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.jost(.semibold, size: 15))
                                Text("NEW ROTATION")
                                    .font(.jost(.semibold, size: 14))
                                    .kerning(1.5)
                            }
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                    }

                    ThinDivider()

                    sectionBlock {
                        HStack(alignment: .bottom) {
                            sectionLabel("CARDIO TYPES")
                            Spacer()
                            Button {
                                Haptics.selection()
                                showCardioReorder = true
                            } label: {
                                Text("REORDER")
                                    .font(.jost(.medium, size: 12))
                                    .kerning(1.5)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 24)
                            .padding(.bottom, 8)
                        }
                        ForEach(Array(orderedAllCardioTypes.enumerated()), id: \.element) { idx, type in
                            cardioTypeRow(type)
                            if idx < orderedAllCardioTypes.count - 1 {
                                ThinDivider().padding(.leading, 24)
                            }
                        }
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("LIMITATIONS")
                        Text("Exercises that stress marked joints are dimmed in the exercise picker.")
                            .font(.jost(.regular, size: 14))
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                        ForEach(BodyLimitation.allCases, id: \.rawValue) { limitation in
                            limitationRow(limitation)
                            if limitation != BodyLimitation.allCases.last {
                                ThinDivider().padding(.leading, 24)
                            }
                        }
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("TRAINING")
                        unitRow
                        ThinDivider().padding(.leading, 24)
                        dateLocaleRow
                        ThinDivider().padding(.leading, 24)
                        timerRow
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("HEALTH")
                        toggleRow(
                            title: "SAVE WORKOUTS TO HEALTH",
                            description: "Your workouts are saved in Apple Health and appear in Activity and Fitness.",
                            isOn: $healthKitSyncEnabled
                        )
                        ThinDivider().padding(.leading, 24)
                        toggleRow(
                            title: "FETCH BODY WEIGHT FROM HEALTH",
                            description: "The app reads your latest recorded value and uses it only to calculate calorie burn.",
                            isOn: $healthKitWeightEnabled
                        )
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("PRIVACY")
                        toggleRow(
                            title: "FACE ID LOCK",
                            description: nil,
                            isOn: $lockEnabled
                        )
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("REMINDERS")
                        toggleRow(
                            title: "TRAINING REMINDERS",
                            description: nil,
                            isOn: Binding(
                                get: { reminderEnabled },
                                set: { newValue in
                                    reminderEnabled = newValue
                                    Task { await applyReminders(enabled: newValue) }
                                }
                            )
                        )
                        if reminderEnabled {
                            ThinDivider().padding(.leading, 24)
                            reminderWeekdaysRow
                            ThinDivider().padding(.leading, 24)
                            reminderTimeRow
                        }
                    }

                    ThinDivider()

                    sectionBlock {
                        sectionLabel("DATA")
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "icloud")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.top, 1)
                            Text("Your data is saved locally and included in iCloud Backup. If you restore from backup, everything is preserved. Setting up a new phone without restoring — or with Backup disabled — will result in data loss. Export CSV as an extra copy.")
                                .font(.jost(.regular, size: 14))
                                .foregroundStyle(Color(.secondaryLabel))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                        actionRow(
                            title: "EXPORT TRAINING DATA",
                            systemImage: "square.and.arrow.up"
                        ) {
                            let items = buildExportItems()
                            guard !items.isEmpty else { return }
                            exportItems = items
                            showExportSheet = true
                        }
                    }

                    ThinDivider()

                    #if DEBUG
                    sectionBlock {
                        sectionLabel("DEBUG")
                        actionRow(title: "RESET ONBOARDING", systemImage: "arrow.counterclockwise") {
                            onboardingCompleted = false
                        }
                    }
                    ThinDivider()
                    #endif

                    sectionBlock {
                        sectionLabel("ABOUT")
                        Button {
                            showWhatsNew = true
                        } label: {
                            HStack {
                                Text("VERSION")
                                    .font(.jost(.semibold, size: 14))
                                    .kerning(1.5)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(appVersion)
                                    .font(.jost(.regular, size: 14))
                                    .foregroundStyle(Color(.secondaryLabel))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    ThinDivider()
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: exportItems)
        }
        .sheet(item: $editingProgram) { program in
            ProgramEditorView(program: program)
        }
        .sheet(isPresented: $showNewProgram) {
            ProgramEditorView(program: nil)
        }
        .sheet(item: $editingRotation) { rotation in
            RotationEditorView(existing: rotation)
        }
        .sheet(isPresented: $showNewRotation) {
            RotationEditorView()
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewSheet()
        }
        .sheet(isPresented: $showProgramReorder) {
            ProgramReorderSheet(programs: programs) { from, to in
                var reordered = programs
                reordered.move(fromOffsets: from, toOffset: to)
                for (i, p) in reordered.enumerated() { p.sortIndex = i }
                try? context.save()
            }
        }
        .sheet(isPresented: $showCardioReorder) {
            CardioReorderSheet(
                orderedTypes: orderedAllCardioTypes,
                selectedTypes: selectedTypes
            ) { from, to in
                var ordered = orderedAllCardioTypes
                ordered.move(fromOffsets: from, toOffset: to)
                cardioTypeOrderRaw = ordered.map(\.rawValue).joined(separator: ",")
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        Text("SETTINGS")
            .font(.jost(.bold, size: 17))
            .kerning(2)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        Text(LocalizedStringKey(title))
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundStyle(Color(.secondaryLabel))
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func toggleRow(title: String, description: String?, isOn: Binding<Bool>) -> some View {
        HStack(alignment: description != nil ? .top : .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(.jost(.semibold, size: 14))
                    .kerning(1.5)
                    .foregroundStyle(.primary)
                if let description {
                    Text(LocalizedStringKey(description))
                        .font(.jost(.regular, size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func actionRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.jost(.medium, size: 16))
                Text(LocalizedStringKey(title))
                    .font(.jost(.semibold, size: 14))
                    .kerning(1.5)
                Spacer()
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Limitation row

    private var bodyLimitationsActive: Set<String> {
        Set(bodyLimitationsRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func limitationRow(_ limitation: BodyLimitation) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { bodyLimitationsActive.contains(limitation.rawValue) },
                set: { on in
                    var active = bodyLimitationsActive
                    if on { active.insert(limitation.rawValue) } else { active.remove(limitation.rawValue) }
                    bodyLimitationsRaw = active.sorted().joined(separator: ",")
                }
            ))
            .labelsHidden()

            Text(limitation.displayName)
                .font(.jost(.semibold, size: 14))
                .kerning(1.5)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Program row

    private func rotationRow(_ rotation: ProgramRotation) -> some View {
        let letters = ["A", "B", "C", "D", "E", "F"]
        let sequence = rotation.programIds.enumerated().map { i, id in
            let prog = programs.first { $0.id.uuidString == id }
            let letter = i < letters.count ? letters[i] : "\(i + 1)"
            return "\(letter): \(prog?.name ?? "—")"
        }.joined(separator: " · ")

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rotation.name.uppercased())
                    .font(.jost(.semibold, size: 14))
                    .kerning(1.5)
                    .foregroundStyle(.primary)
                if !sequence.isEmpty {
                    Text(sequence)
                        .font(.jost(.medium, size: 12))
                        .kerning(1)
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(2)
                }
            }

            Spacer()

            Button {
                editingRotation = rotation
            } label: {
                Image(systemName: "pencil")
                    .font(.jost(.medium, size: 15))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit rotation \(rotation.name)")

            Button {
                context.delete(rotation)
                try? context.save()
            } label: {
                Image(systemName: "trash")
                    .font(.jost(.medium, size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete rotation \(rotation.name)")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private func programRow(_ program: WorkoutProgram) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { program.isOnTrainingPage },
                set: { program.isOnTrainingPage = $0; do { try context.save() } catch {
     #if DEBUG
     logger.error("context.save failed: \(error)")
     #endif
 } }
            ))
            .labelsHidden()
            .tint(Color(program.colorName))

            VStack(alignment: .leading, spacing: 2) {
                Text(program.name.uppercased())
                    .font(.jost(.semibold, size: 14))
                    .kerning(1.5)
                    .foregroundStyle(.primary)
                Text("\(program.sortedExercises.count) \(String(localized: "EXERCISES")) · \(program.sortedExercises.first?.setCount ?? 3) SET")
                    .font(.jost(.medium, size: 12))
                    .kerning(1.5)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            Button {
                editingProgram = program
            } label: {
                Image(systemName: "pencil")
                    .font(.jost(.medium, size: 15))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: String(localized: "Edit %@"), program.name))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - Cardio type row

    private func cardioTypeRow(_ type: CardioType) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { selectedTypes.contains(type.rawValue) },
                set: { on in
                    var types = selectedTypes
                    if on { types.insert(type.rawValue) } else { types.remove(type.rawValue) }
                    selectedCardioTypesRaw = types.joined(separator: ",")
                }
            ))
            .labelsHidden()

            Text(type.displayName.uppercased())
                .font(.jost(.semibold, size: 14))
                .kerning(1.5)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Timer row

    private var unitRow: some View {
        HStack {
            Text("UNITS")
                .font(.jost(.semibold, size: 14))
                .kerning(1.5)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 4) {
                ForEach([(false, "KG / KM"), (true, "LBS / MI")], id: \.0) { imperial, label in
                    Button {
                        Haptics.selection()
                        useImperialUnits = imperial
                    } label: {
                        Text(label)
                            .font(.jost(.semibold, size: 12))
                            .kerning(1)
                            .foregroundStyle(useImperialUnits == imperial ? .white : Color(.secondaryLabel))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(
                                useImperialUnits == imperial
                                    ? Color.homeAccent
                                    : Color(.secondarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var dateLocaleRow: some View {
        HStack {
            Text("DATE LANGUAGE")
                .font(.jost(.semibold, size: 14))
                .kerning(1.5)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 4) {
                ForEach([("", "SYSTEM"), ("sv_SE", "SV"), ("en_US", "EN")], id: \.0) { id, label in
                    Button {
                        Haptics.selection()
                        dateLocaleIdentifier = id
                    } label: {
                        Text(label)
                            .font(.jost(.semibold, size: 12))
                            .kerning(1)
                            .foregroundStyle(dateLocaleIdentifier == id ? .white : Color(.secondaryLabel))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(
                                dateLocaleIdentifier == id
                                    ? Color.homeAccent
                                    : Color(.secondarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var timerRow: some View {
        HStack {
            Text("REST TIMER")
                .font(.jost(.semibold, size: 14))
                .kerning(1.5)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 4) {
                ForEach([0, 30, 60, 90, 120], id: \.self) { secs in
                    Button {
                        Haptics.selection()
                        restTimerSeconds = secs
                    } label: {
                        Text(secs == 0 ? "OFF" : secs < 120 ? "\(secs)s" : "2m")
                            .font(.jost(.semibold, size: 12))
                            .kerning(1)
                            .foregroundStyle(restTimerSeconds == secs ? .white : Color(.secondaryLabel))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(
                                restTimerSeconds == secs
                                    ? Color.homeAccent
                                    : Color(.secondarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
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


    private func writeCSV(filename: String, content: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Reminders

    private var reminderWeekdays: Set<Int> {
        get { Set(reminderWeekdaysRaw.split(separator: ",").compactMap { Int($0) }) }
    }

    private func setReminderWeekdays(_ days: Set<Int>) {
        reminderWeekdaysRaw = days.sorted().map(String.init).joined(separator: ",")
    }

    private var reminderWeekdaysRow: some View {
        let days = [(2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")]
        let selected = reminderWeekdays
        return HStack(spacing: 6) {
            ForEach(days, id: \.0) { weekday, label in
                let isOn = selected.contains(weekday)
                Button {
                    var updated = selected
                    if isOn { updated.remove(weekday) } else { updated.insert(weekday) }
                    setReminderWeekdays(updated)
                    Task { await applyReminders(enabled: reminderEnabled) }
                } label: {
                    Text(label)
                        .font(.jost(.medium, size: 12))
                        .kerning(1)
                        .foregroundStyle(isOn ? Color.appBackground : Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isOn ? Color.homeAccent : Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var reminderTimeRow: some View {
        let (sugH, sugM) = ReminderManager.suggestedTime(from: Array(sessions))
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TIME")
                    .font(.jost(.medium, size: 12))
                    .kerning(1.5)
                    .foregroundStyle(Color(.secondaryLabel))
                Text("Based on your last session start")
                    .font(.jost(.regular, size: 13))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
                        c.hour = reminderHour; c.minute = reminderMinute
                        return Calendar.current.date(from: c) ?? Date()
                    },
                    set: { date in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                        reminderHour = c.hour ?? sugH
                        reminderMinute = c.minute ?? sugM
                        Task { await applyReminders(enabled: reminderEnabled) }
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .onAppear {
            // Auto-set time from history on first enable
            if reminderHour == 17 && reminderMinute == 0 {
                reminderHour = sugH
                reminderMinute = sugM
            }
        }
    }

    private func applyReminders(enabled: Bool) async {
        guard enabled else {
            await ReminderManager.shared.cancel()
            return
        }
        let authorized = await ReminderManager.shared.requestAuthorization()
        guard authorized else {
            reminderEnabled = false
            return
        }
        await ReminderManager.shared.schedule(
            weekdays: reminderWeekdays,
            hour: reminderHour,
            minute: reminderMinute
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Reorder sheets

private struct ProgramReorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let programs: [WorkoutProgram]
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(programs) { program in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(program.colorName))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(program.name.uppercased())
                                .font(.jost(.semibold, size: 14))
                                .kerning(1.5)
                                .foregroundStyle(.primary)
                            Text("\(program.sortedExercises.count) \(String(localized: "EXERCISES")) · \(program.sortedExercises.first?.setCount ?? 3) SET")
                                .font(.jost(.medium, size: 12))
                                .kerning(1.5)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: onMove)
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "Reorder Programs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                        .font(.jost(.semibold, size: 15))
                }
            }
        }
    }
}

private struct CardioReorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let orderedTypes: [CardioType]
    let selectedTypes: Set<String>
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(orderedTypes, id: \.self) { type in
                    HStack(spacing: 12) {
                        Image(systemName: selectedTypes.contains(type.rawValue) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(selectedTypes.contains(type.rawValue) ? Color.workoutAccent : Color(.tertiaryLabel))
                        Text(type.displayName.uppercased())
                            .font(.jost(.semibold, size: 14))
                            .kerning(1.5)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: onMove)
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "Reorder Cardio Types"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                        .font(.jost(.semibold, size: 15))
                }
            }
        }
    }
}
