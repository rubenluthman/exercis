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
        let log = ExerciseLog(name: "Safety Bar Squat", orderIndex: 0); log.session = s; ctx.insert(log)
        for i in 1...3 {
            let set = SetLog(setNumber: i, weight: weight - Double(i - 1) * 2.5, reps: 6)
            set.exerciseLog = log; ctx.insert(set)
        }
    }

    return ExerciseChartSheet(exerciseName: "Safety Bar Squat")
        .modelContainer(container)
}

struct ExerciseChartSheet: View {
    let exerciseName: String
    @Query(sort: \WorkoutSession.date) private var allSessions: [WorkoutSession]

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
    }

    private var dataPoints: [DataPoint] {
        allSessions.compactMap { session in
            guard let log = session.exerciseLogs.first(where: { $0.name == exerciseName }) else { return nil }
            let max = log.sets.map(\.weight).filter { $0 > 0 }.max() ?? 0
            guard max > 0 else { return nil }
            return DataPoint(date: session.date, maxWeight: max)
        }
    }

    private var bestWeight: Double  { dataPoints.map(\.maxWeight).max() ?? 0 }
    private var lastWeight: Double  { dataPoints.last?.maxWeight ?? 0 }
    private var yMin: Double        { (dataPoints.map(\.maxWeight).min() ?? 0) * 0.95 }
    private var yMax: Double        { bestWeight * 1.05 }

    private var spansMultipleYears: Bool {
        guard let first = dataPoints.first?.date, let last = dataPoints.last?.date else { return false }
        return Calendar.current.component(.year, from: first) != Calendar.current.component(.year, from: last)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(exerciseName.uppercased())
                .font(.jost(.bold, size: 13))
                .kerning(2)
                .foregroundColor(Color.historyAccent)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            if dataPoints.count < 2 {
                Spacer()
                Text(dataPoints.isEmpty ? "Inga loggade pass ännu." : "Behöver minst två pass för att visa graf.")
                    .font(.jost(.regular, size: 14))
                    .foregroundColor(Color(white: 0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("KG", point.maxWeight)
                    )
                    .foregroundStyle(Color.historyAccent)

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value("KG", point.maxWeight)
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
                                        .foregroundColor(Color(white: 0.5))
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text(month)
                                        .font(.jost(.regular, size: 10))
                                        .foregroundColor(Color(white: 0.5))
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
                                    .foregroundColor(Color(white: 0.5))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .frame(height: 200)

                ThinDivider()
                    .padding(.top, 20)

                HStack(alignment: .top, spacing: 0) {
                    statBlock(label: "BÄSTA", value: formatWeight(bestWeight), unit: "kg", alignment: .leading)
                    statBlock(label: "SENASTE", value: formatWeight(lastWeight), unit: "kg", alignment: .center)
                    statBlock(label: "PASS", value: "\(dataPoints.count)", alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()
            }
        }
        .background(Color.appBackground)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func statBlock(label: String, value: String, unit: String? = nil, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundColor(Color(white: 0.5))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.jost(.semibold, size: 22))
                    .foregroundColor(.black)
                if let unit {
                    Text(unit)
                        .font(.jost(.semibold, size: 22))
                        .foregroundColor(.black)
                }
            }
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }
}
