import SwiftUI
import SwiftData
import Charts

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CardioSession.self, configurations: config)
    let ctx = container.mainContext

    func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: Date())! }

    let scores = [(-180, 6), (-150, 7), (-120, 7), (-90, 8), (-60, 7), (-30, 9), (-2, 8)]
    for (offset, score) in scores {
        let s = CardioSession(date: day(offset), durationMinutes: 40, cardioType: "CROSSTRAINER")
        s.effortScore = score
        ctx.insert(s)
    }

    return CardioEffortChartSheet(cardioType: "CROSSTRAINER")
        .modelContainer(container)
}

struct CardioEffortChartSheet: View {
    let cardioType: String
    @Query(sort: \CardioSession.date) private var allSessions: [CardioSession]

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Int
    }

    private var dataPoints: [DataPoint] {
        allSessions
            .filter { $0.cardioType == cardioType }
            .compactMap { s in
                guard let score = s.effortScore else { return nil }
                return DataPoint(date: s.date, score: score)
            }
    }

    private var easiest: Int { dataPoints.map(\.score).min() ?? 0 }
    private var hardest: Int  { dataPoints.map(\.score).max() ?? 0 }
    private var latest: Int   { dataPoints.last?.score ?? 0 }

    private var spansMultipleYears: Bool {
        guard let first = dataPoints.first?.date, let last = dataPoints.last?.date else { return false }
        return Calendar.current.component(.year, from: first) != Calendar.current.component(.year, from: last)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EFFORT")
                .font(.jost(.bold, size: 13))
                .kerning(2)
                .foregroundStyle(Color.historyAccent)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            if dataPoints.count < 2 {
                ChartEmptyState(isEmpty: dataPoints.isEmpty)
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("Ansträngning", point.score)
                    )
                    .foregroundStyle(Color.historyAccent)

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value("Ansträngning", point.score)
                    )
                    .foregroundStyle(Color.historyAccent)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...11)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine().foregroundStyle(Color.appDivider)
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                let month = date.formatted(.dateTime.month(.abbreviated).locale(appLocale())).uppercased().replacingOccurrences(of: ".", with: "")
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
                            if let v = value.as(Int.self) {
                                Text("\(v)")
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
                    statBlock(label: "EASIEST", value: "\(easiest)", unit: "/10", alignment: .leading)
                    statBlock(label: "LATEST", value: "\(latest)", unit: "/10", alignment: .center)
                    statBlock(label: "HARDEST", value: "\(hardest)", unit: "/10", alignment: .trailing)
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
        VStack(alignment: .leading, spacing: 4) {
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
