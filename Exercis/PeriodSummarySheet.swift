import SwiftUI
import SwiftData
import Charts

struct SummaryPeriod: Identifiable {
    let year: Int
    let month: Int?
    var id: String { month.map { "\(year)-\(String(format: "%02d", $0))" } ?? "\(year)" }
}

struct PeriodSummarySheet: View {
    let period: SummaryPeriod
    @Query private var workouts: [WorkoutSession]
    @Query private var cardio: [CardioSession]

    private let cal = Calendar.current

    init(period: SummaryPeriod) {
        self.period = period
        let cal = Calendar.current
        let start: Date
        let end: Date
        if let month = period.month {
            var c = DateComponents(); c.year = period.year; c.month = month; c.day = 1
            start = cal.date(from: c) ?? .distantPast
            end = cal.date(byAdding: .month, value: 1, to: start) ?? .distantFuture
        } else {
            var c = DateComponents(); c.year = period.year; c.month = 1; c.day = 1
            start = cal.date(from: c) ?? .distantPast
            end = cal.date(byAdding: .year, value: 1, to: start) ?? .distantFuture
        }
        _workouts = Query(filter: #Predicate<WorkoutSession> { $0.date >= start && $0.date < end },
                          sort: \.date)
        _cardio   = Query(filter: #Predicate<CardioSession>  { $0.date >= start && $0.date < end },
                          sort: \.date)
    }

    // MARK: - Stats

    private var totalVolume: Double {
        workouts.reduce(0.0) { t, s in
            t + s.exerciseLogs.reduce(0.0) { lt, l in
                lt + l.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            }
        }
    }

    private var totalMinutes: Double {
        cardio.reduce(0.0) { $0 + $1.durationMinutes }
    }

    private var volumeText: (String, String?) {
        guard totalVolume > 0 else { return ("—", nil) }
        if totalVolume >= 1000 {
            return (formatWeight(totalVolume / 1000), " TON")
        }
        return (formatWeight(totalVolume), "kg")
    }

    // MARK: - Bar chart

    private struct BarEntry: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let isStrength: Bool
    }

    private var barData: [BarEntry] {
        var strength = [Int: Int]()
        var cardioMap = [Int: Int]()

        for s in workouts { strength[bucketIndex(s.date), default: 0] += 1 }
        for s in cardio   { cardioMap[bucketIndex(s.date), default: 0] += 1 }

        var result: [BarEntry] = []
        for i in bucketRange {
            let lbl = bucketLabel(i)
            if let n = strength[i], n > 0 {
                result.append(BarEntry(label: lbl, count: n, isStrength: true))
            }
            if let n = cardioMap[i], n > 0 {
                result.append(BarEntry(label: lbl, count: n, isStrength: false))
            }
        }
        return result
    }

    private func bucketIndex(_ date: Date) -> Int {
        cal.component(.month, from: date)
    }

    private var bucketRange: ClosedRange<Int> { 1...12 }

    private func bucketLabel(_ i: Int) -> String {
        var comps = DateComponents()
        comps.year = period.year; comps.month = i; comps.day = 1
        guard let date = cal.date(from: comps) else { return "" }
        return date.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "sv_SE")))
            .uppercased().replacingOccurrences(of: ".", with: "")
    }

    private var domainLabels: [String] {
        bucketRange.map { bucketLabel($0) }
    }

    // MARK: - Title

    private var title: String {
        if let month = period.month {
            var comps = DateComponents()
            comps.year = period.year; comps.month = month; comps.day = 1
            guard let date = cal.date(from: comps) else { return "" }
            return date.formatted(.dateTime.month(.wide).locale(Locale(identifier: "sv_SE"))).uppercased()
        }
        return "\(period.year)"
    }

    // MARK: - Month dot helpers

    private var daysInMonth: Int {
        guard let month = period.month else { return 0 }
        var comps = DateComponents()
        comps.year = period.year; comps.month = month
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    private var workoutDays: Set<Int> {
        Set(workouts.map { cal.component(.day, from: $0.date) })
    }

    private var cardioDays: Set<Int> {
        Set(cardio.map { cal.component(.day, from: $0.date) })
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.jost(.bold, size: 13))
                .kerning(2)
                .foregroundColor(Color.historyAccent)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            if period.month != nil {
                monthContent
            } else {
                yearContent
            }
        }
        .background(Color.appBackground)
        .presentationDragIndicator(.visible)
        .presentationDetents(period.month != nil ? [.height(280), .large] : [.medium, .large])
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            statBlock(label: "STYRKA",    value: workouts.count > 0 ? "\(workouts.count)" : "—",    alignment: .leading)
            statBlock(label: "VOLYM",     value: volumeText.0, unit: volumeText.1,                  alignment: .leading)
            statBlock(label: "KONDITION", value: cardio.count > 0 ? "\(cardio.count)" : "—",        alignment: .trailing)
            statBlock(label: "TID",       value: totalMinutes > 0 ? formatWeight(totalMinutes) : "—",
                      unit: totalMinutes > 0 ? " MIN" : nil,                                         alignment: .trailing)
        }
        .padding(.horizontal, 24)
    }

    // Month view: stats then dots, both at top
    private var monthContent: some View {
        VStack(spacing: 0) {
            statsRow
                .padding(.bottom, 20)
            ThinDivider()
            dotRow
            Spacer()
        }
    }

    private var dotRow: some View {
        HStack(spacing: 0) {
            ForEach(1...max(1, daysInMonth), id: \.self) { day in
                dotCircle(
                    strength: workoutDays.contains(day),
                    cardio:   cardioDays.contains(day)
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func dotCircle(strength: Bool, cardio: Bool) -> some View {
        if strength && cardio {
            Circle()
                .fill(LinearGradient(colors: [.homeAccent, .workoutAccent], startPoint: .leading, endPoint: .trailing))
                .frame(width: 9, height: 9)
        } else if strength {
            Circle().fill(Color.homeAccent).frame(width: 9, height: 9)
        } else if cardio {
            Circle().fill(Color.workoutAccent).frame(width: 9, height: 9)
        } else {
            Circle().fill(Color(.tertiarySystemFill)).frame(width: 9, height: 9)
        }
    }

    // Year view: stats at top, bars below
    @ViewBuilder
    private var yearContent: some View {
        statsRow

        if barData.isEmpty {
            Spacer()
            Text("Inga pass under perioden.")
                .font(.jost(.regular, size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        } else {
            ThinDivider()

            HStack(spacing: 12) {
                legendDot(color: .homeAccent,    label: "STYRKA")
                legendDot(color: .workoutAccent, label: "KONDITION")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Chart(barData) { entry in
                BarMark(
                    x: .value("Period", entry.label),
                    y: .value("Pass",   entry.count)
                )
                .foregroundStyle(entry.isStrength ? Color.homeAccent : Color.workoutAccent)
            }
            .chartXScale(domain: domainLabels)
            .chartXAxis {
                AxisMarks(values: domainLabels) { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(s)
                                .font(.jost(.regular, size: 10))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.appDivider)
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.jost(.regular, size: 10))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func statBlock(label: String, value: String, unit: String? = nil, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundColor(Color(.secondaryLabel))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.jost(.semibold, size: 22))
                    .foregroundColor(.primary)
                if let unit {
                    Text(unit)
                        .font(.jost(.semibold, size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.jost(.medium, size: 9))
                .kerning(1.5)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, CardioSession.self, configurations: config)
    let ctx = container.mainContext

    func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: Date())! }

    for offset in [0, -4, -9, -13, -18, -23] {
        let s = WorkoutSession(date: day(offset)); ctx.insert(s)
    }
    for offset in [-2, -11, -20] {
        ctx.insert(CardioSession(date: day(offset), durationMinutes: 40, cardioType: "CROSSTRAINER"))
    }
    let log = ExerciseLog(name: "Barbell Back Squat", orderIndex: 0)
    log.session = (try! ctx.fetch(FetchDescriptor<WorkoutSession>())).first!
    ctx.insert(log)
    for (i, (w, r)) in [(90.0, 7), (90.0, 6), (87.5, 6)].enumerated() {
        let s = SetLog(setNumber: i + 1, weight: w, reps: r); s.exerciseLog = log; ctx.insert(s)
    }

    let cal = Calendar.current
    let now = Date()
    let period = SummaryPeriod(year: cal.component(.year, from: now), month: cal.component(.month, from: now))
    return PeriodSummarySheet(period: period)
        .modelContainer(container)
}
