import SwiftUI
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, CardioSession.self, configurations: config)
    let ctx = container.mainContext

    func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: Date())! }

    let s1 = WorkoutSession(date: day(-2)); ctx.insert(s1)
    let log1 = ExerciseLog(name: "Barbell Back Squat", orderIndex: 0); log1.session = s1; ctx.insert(log1)
    for (i, (w, r)) in [(90.0, 7), (90.0, 6), (90.0, 6)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r); s.exerciseLog = log1; ctx.insert(s)
    }
    ctx.insert(CardioSession(date: day(-5), durationMinutes: 35, cardioType: "CROSSTRAINER"))
    let s2 = WorkoutSession(date: day(-9)); ctx.insert(s2)
    let log2 = ExerciseLog(name: "Romanian Deadlift", orderIndex: 0); log2.session = s2; ctx.insert(log2)
    for (i, (w, r)) in [(80.0, 8), (80.0, 7), (80.0, 7)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r); s.exerciseLog = log2; ctx.insert(s)
    }
    let s3 = WorkoutSession(date: day(-14)); ctx.insert(s3)
    let s4 = WorkoutSession(date: day(-32)); ctx.insert(s4)
    let log4 = ExerciseLog(name: "Seated Cable Row", orderIndex: 0); log4.session = s4; ctx.insert(log4)
    for (i, (w, r)) in [(60.0, 10), (60.0, 9), (60.0, 9)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r); s.exerciseLog = log4; ctx.insert(s)
    }
    ctx.insert(CardioSession(date: day(-36), durationMinutes: 45, cardioType: "CYKEL"))
    let s5 = WorkoutSession(date: day(-42)); ctx.insert(s5)
    ctx.insert(CardioSession(date: day(-47), durationMinutes: 30, cardioType: "RODDMASKIN"))
    let s6 = WorkoutSession(date: day(-62)); ctx.insert(s6)
    let log6 = ExerciseLog(name: "Neutral-Grip Lat Pulldown", orderIndex: 0); log6.session = s6; ctx.insert(log6)
    for (i, (w, r)) in [(55.0, 12), (55.0, 11), (55.0, 10)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r); s.exerciseLog = log6; ctx.insert(s)
    }
    ctx.insert(CardioSession(date: day(-70), durationMinutes: 40, cardioType: "CROSSTRAINER"))
    let s7 = WorkoutSession(date: day(-155)); ctx.insert(s7)
    let log7 = ExerciseLog(name: "Barbell Back Squat", orderIndex: 0); log7.session = s7; ctx.insert(log7)
    for (i, (w, r)) in [(85.0, 7), (85.0, 6), (85.0, 6)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r); s.exerciseLog = log7; ctx.insert(s)
    }
    ctx.insert(CardioSession(date: day(-163), durationMinutes: 30, cardioType: "CYKEL"))

    return NavigationStack { HistoryView().modelContainer(container) }
}

enum HistoryEntry: Identifiable {
    case workout(WorkoutSession)
    case cardio(CardioSession)

    var id: String {
        switch self {
        case .workout(let s): return "w-\(s.id)"
        case .cardio(let s):  return "c-\(s.id)"
        }
    }
    var date: Date {
        switch self {
        case .workout(let s): return s.date
        case .cardio(let s):  return s.date
        }
    }
}

struct MonthGroup: Identifiable {
    let year: Int
    let month: Int
    let entries: [HistoryEntry]

    var id: String { "\(year)-\(String(format: "%02d", month))" }
    var workoutCount: Int { entries.filter { if case .workout = $0 { return true }; return false }.count }
    var cardioCount: Int  { entries.filter { if case .cardio  = $0 { return true }; return false }.count }
}

enum HistoryRow: Identifiable {
    case year(Int)
    case month(MonthGroup)

    var id: String {
        switch self {
        case .year(let y):  return "year-\(y)"
        case .month(let g): return "month-\(g.id)"
        }
    }
}

func groupHistoryEntries(_ entries: [HistoryEntry]) -> [MonthGroup] {
    let calendar = Calendar.current
    var groups: [String: [HistoryEntry]] = [:]
    for entry in entries {
        let comps = calendar.dateComponents([.year, .month], from: entry.date)
        let key = "\(comps.year!)-\(String(format: "%02d", comps.month!))"
        groups[key, default: []].append(entry)
    }
    return groups
        .map { key, entries in
            let parts = key.split(separator: "-")
            return MonthGroup(
                year: Int(parts[0])!,
                month: Int(parts[1])!,
                entries: entries.sorted { $0.date > $1.date }
            )
        }
        .sorted { ($0.year, $0.month) > ($1.year, $1.month) }
}

func buildHistoryRows(_ groups: [MonthGroup]) -> [HistoryRow] {
    let showYears = Set(groups.map(\.year)).count > 1
    var rows: [HistoryRow] = []
    var lastYear: Int? = nil
    for group in groups {
        if showYears && group.year != lastYear {
            rows.append(.year(group.year))
            lastYear = group.year
        }
        rows.append(.month(group))
    }
    return rows
}

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]

    @State private var expandedIDs: Set<String> = []
    @State private var collapsedMonths: Set<String> = []
    @State private var entryToDelete: HistoryEntry? = nil
    @State private var summaryPeriod: SummaryPeriod? = nil

    private var entries: [HistoryEntry] {
        let w = workoutSessions.map { HistoryEntry.workout($0) }
        let c = cardioSessions.map { HistoryEntry.cardio($0) }
        return (w + c).sorted { $0.date > $1.date }
    }

    private var groupedEntries: [MonthGroup] { groupHistoryEntries(entries) }

    private var historyRows: [HistoryRow] { buildHistoryRows(groupedEntries) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(historyRows) { row in
                                switch row {
                                case .year(let year):
                                    yearHeader(year)
                                case .month(let group):
                                    let isCollapsed = collapsedMonths.contains(group.id)
                                    monthHeader(group, isCollapsed: isCollapsed)
                                    if !isCollapsed {
                                        ForEach(group.entries) { entry in
                                            entryView(entry)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .softScrollEdge()
                }
            }
        }
        .alert("Delete workout?", isPresented: Binding(
            get: { entryToDelete != nil },
            set: { if !$0 { entryToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let entry = entryToDelete else { return }
                Haptics.notification(.warning)
                deleteEntry(entry)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        }
        .sheet(item: $summaryPeriod) { period in
            PeriodSummarySheet(period: period)
        }
        .onAppear {
            if expandedIDs.isEmpty && collapsedMonths.isEmpty {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    if let first = entries.first { expandedIDs.insert(first.id) }
                    let allIDs = Set(groupedEntries.map(\.id))
                    if let latest = groupedEntries.first?.id {
                        collapsedMonths = allIDs.subtracting([latest])
                    }
                }
            }
        }
    }

    // MARK: - Sub-views

    private func yearHeader(_ year: Int) -> some View {
        Button {
            Haptics.selection()
            summaryPeriod = SummaryPeriod(year: year, month: nil)
        } label: {
            Text(verbatim: String(year))
                .font(.jost(.medium, size: 11))
                .kerning(2)
                .foregroundColor(Color(.tertiaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func monthHeader(_ group: MonthGroup, isCollapsed: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Button {
                Haptics.selection()
                summaryPeriod = SummaryPeriod(year: group.year, month: group.month)
            } label: {
                Text(monthName(year: group.year, month: group.month))
                    .font(.jost(.bold, size: 13))
                    .kerning(2)
                    .foregroundColor(Color.historyAccent)
            }
            .buttonStyle(.plain)

            Spacer()

            if isCollapsed {
                Image(systemName: "chevron.right")
                    .font(.jost(.medium, size: 10))
                    .foregroundColor(Color(.secondaryLabel))
            } else {
                HStack(spacing: 10) {
                    if group.workoutCount > 0 { Text(String(format: String(localized: "%d STRENGTH"), group.workoutCount)) }
                    if group.cardioCount > 0  { Text(String(format: String(localized: "%d CARDIO"), group.cardioCount)) }
                }
                .font(.jost(.regular, size: 11))
                .kerning(1)
                .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.22)) {
                if collapsedMonths.contains(group.id) {
                    collapsedMonths.remove(group.id)
                } else {
                    collapsedMonths.insert(group.id)
                }
            }
        }
    }

    @ViewBuilder
    private func entryView(_ entry: HistoryEntry) -> some View {
        let isExpanded = expandedIDs.contains(entry.id)
        let toggle = {
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.22)) {
                if isExpanded { expandedIDs.remove(entry.id) }
                else { expandedIDs.insert(entry.id) }
            }
        }

        switch entry {
        case .workout(let session):
            HistoryCard(session: session, isExpanded: isExpanded, onTap: toggle, onDelete: { entryToDelete = entry })
        case .cardio(let session):
            CardioCard(session: session, isExpanded: isExpanded, onTap: toggle, onDelete: { entryToDelete = entry })
        }
    }

    private var headerRow: some View {
        Text("HISTORY")
            .font(.jost(.bold, size: 17))
            .kerning(2)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
    }

    // MARK: - Logic

    private func deleteEntry(_ entry: HistoryEntry) {
        switch entry {
        case .workout(let session):
            if let uuid = session.healthKitID {
                Task { await HealthKitManager.shared.deleteWorkout(uuid: uuid) }
            }
            context.delete(session)
        case .cardio(let session):
            if let uuid = session.healthKitID {
                Task { await HealthKitManager.shared.deleteWorkout(uuid: uuid) }
            }
            let sessionsForType = cardioSessions.filter { $0.cardioType == session.cardioType }
            if sessionsForType.first?.id == session.id {
                let next = sessionsForType.dropFirst().first
                if let next {
                    UserDefaults.standard.set(formatWeight(next.durationMinutes), forKey: "cardioSavedDuration_\(session.cardioType)")
                    if let km = next.distanceKm {
                        UserDefaults.standard.set(formatWeight(km), forKey: "cardioSavedDistance_\(session.cardioType)")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "cardioSavedDistance_\(session.cardioType)")
                    }
                    if let score = next.effortScore {
                        UserDefaults.standard.set(score, forKey: "cardioEffortScore_\(session.cardioType)")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "cardioEffortScore_\(session.cardioType)")
                    }
                } else {
                    UserDefaults.standard.removeObject(forKey: "cardioSavedDuration_\(session.cardioType)")
                    UserDefaults.standard.removeObject(forKey: "cardioSavedDistance_\(session.cardioType)")
                    UserDefaults.standard.removeObject(forKey: "cardioEffortScore_\(session.cardioType)")
                }
            }
            context.delete(session)
        }
        try? context.save()
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No saved workouts yet.")
                .font(.jost(.regular, size: 14))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
        }
    }

    private func monthName(year: Int, month: Int) -> String {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return date.formatted(.dateTime.month(.wide).locale(Locale(identifier: "sv_SE"))).uppercased()
    }
}
