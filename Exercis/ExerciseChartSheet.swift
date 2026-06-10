import SwiftUI
import SwiftData
import Charts

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    let ctx = container.mainContext

    func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: Date())! }

    let weights: [(Int, Double)] = [
        (-480, 75), (-420, 77.5), (-360, 80), (-300, 80),
        (-240, 82.5), (-180, 85), (-120, 85), (-60, 87.5), (-2, 90)
    ]
    for (offset, weight) in weights {
        let s = WorkoutSession(date: day(offset)); ctx.insert(s)
        let log = ExerciseLog(name: "Barbell Back Squat", orderIndex: 0); log.session = s; ctx.insert(log)
        for i in 1...3 {
            let set = SetLog(setNumber: i, weight: weight - Double(i - 1) * 2.5, reps: 6)
            set.exerciseLog = log; ctx.insert(set)
        }
    }

    return ExerciseChartSheet(exerciseName: "Barbell Back Squat")
        .modelContainer(container)
}

struct ExerciseChartSheet: View {
    let exerciseName: String
    @Query(sort: \WorkoutSession.date) private var allSessions: [WorkoutSession]
    @State private var showVolume = false

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let e1RM: Double
        let volume: Double
    }

    func epley(weight: Double, reps: Int) -> Double {
        epleyE1RM(weight: weight, reps: reps)
    }

    private var dataPoints: [DataPoint] {
        allSessions.compactMap { session in
            guard let log = session.exerciseLogs.first(where: { $0.name == exerciseName }) else { return nil }
            let best = log.sets.map { epley(weight: $0.weight, reps: $0.reps) }.max() ?? 0
            guard best > 0 else { return nil }
            let vol = log.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            return DataPoint(date: session.date, e1RM: best, volume: vol)
        }
    }

    private var activeValues: [Double] { showVolume ? dataPoints.map(\.volume) : dataPoints.map(\.e1RM) }
    private var bestE1RM: Double  { dataPoints.map(\.e1RM).max() ?? 0 }
    private var lastE1RM: Double  { dataPoints.last?.e1RM ?? 0 }
    private var bestVol: Double   { dataPoints.map(\.volume).max() ?? 0 }
    private var lastVol: Double   { dataPoints.last?.volume ?? 0 }
    private var yMin: Double { (activeValues.min() ?? 0) * 0.95 }
    private var yMax: Double { (activeValues.max() ?? 0) * 1.05 }

    private var spansMultipleYears: Bool {
        guard let first = dataPoints.first?.date, let last = dataPoints.last?.date else { return false }
        return Calendar.current.component(.year, from: first) != Calendar.current.component(.year, from: last)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text((ExerciseDef.find(name: exerciseName)?.displayName ?? exerciseName).uppercased())
                    .font(.jost(.bold, size: 13))
                    .kerning(2)
                    .foregroundStyle(Color.historyAccent)
                Spacer()
                HStack(spacing: 0) {
                    Button("1RM") { withAnimation(.easeInOut(duration: 0.22)) { showVolume = false } }
                        .font(.jost(.semibold, size: 12))
                        .kerning(1.5)
                        .foregroundStyle(showVolume ? Color(.secondaryLabel) : Color.historyAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    Button("VOL") { withAnimation(.easeInOut(duration: 0.22)) { showVolume = true } }
                        .font(.jost(.semibold, size: 12))
                        .kerning(1.5)
                        .foregroundStyle(showVolume ? Color.historyAccent : Color(.secondaryLabel))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.appDivider, lineWidth: 0.5))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            if dataPoints.count < 2 {
                ChartEmptyState(isEmpty: dataPoints.isEmpty)
            } else {
                Chart(dataPoints) { point in
                    let yVal = showVolume ? point.volume : point.e1RM
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("KG", yVal)
                    )
                    .foregroundStyle(Color.historyAccent)

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value("KG", yVal)
                    )
                    .foregroundStyle(Color.historyAccent)
                    .symbolSize(30)
                }
                .chartYScale(domain: yMin...yMax)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine().foregroundStyle(Color.appDivider)
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                let month = date.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "sv_SE"))).uppercased().replacingOccurrences(of: ".", with: "")
                                if spansMultipleYears {
                                    let yr = Calendar.current.component(.year, from: date) % 100
                                    Text("\(month)\n\(String(format: "%02d", yr))")
                                        .font(.jost(.regular, size: 10))
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text(month)
                                        .font(.jost(.regular, size: 10))
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.appDivider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatWeight(v))
                                    .font(.jost(.regular, size: 10))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .frame(height: 200)

                ThinDivider()
                    .padding(.top, 20)

                HStack(alignment: .top, spacing: 0) {
                    statBlock(label: "BEST",    value: formatWeight(showVolume ? bestVol : bestE1RM), unit: showVolume ? "kg" : "kg", alignment: .leading)
                    statBlock(label: "LATEST",  value: formatWeight(showVolume ? lastVol : lastE1RM), unit: "kg", alignment: .center)
                    statBlock(label: "SESSIONS",value: "\(dataPoints.count)", alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()
            }
        }

        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func statBlock(label: String, value: String, unit: String? = nil, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.jost(.medium, size: 11))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.jost(.semibold, size: 22))
                    .foregroundStyle(.primary)
                if let unit {
                    Text(unit)
                        .font(.jost(.semibold, size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }
}
