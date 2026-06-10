import SwiftUI
import SwiftData
import Charts

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CardioSession.self, configurations: config)
    let ctx = container.mainContext

    func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: Date())! }

    let sessions: [(Int, Double, Double?)] = [
        (-480, 25, nil), (-420, 30, 4.0), (-360, 30, 4.2), (-300, 35, 5.0),
        (-240, 35, 5.1), (-180, 40, 6.0), (-120, 40, 6.3), (-60, 45, 7.0), (-2, 50, 7.5)
    ]
    for (offset, minutes, km) in sessions {
        ctx.insert(CardioSession(date: day(offset), durationMinutes: minutes, cardioType: "CROSSTRAINER", distanceKm: km))
    }

    return CardioChartSheet(cardioType: "CROSSTRAINER")
        .modelContainer(container)
}

struct CardioChartSheet: View {
    let cardioType: String
    @Query(sort: \CardioSession.date) private var allSessions: [CardioSession]
    @State private var showDistance = false

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var durationPoints: [DataPoint] {
        allSessions
            .filter { $0.cardioType == cardioType && $0.durationMinutes > 0 }
            .map { DataPoint(date: $0.date, value: Double($0.durationMinutes)) }
    }

    private var distancePoints: [DataPoint] {
        allSessions
            .filter { $0.cardioType == cardioType }
            .compactMap { s in
                guard let km = s.distanceKm, km > 0 else { return nil }
                return DataPoint(date: s.date, value: km)
            }
    }

    private var hasDistanceData: Bool { distancePoints.count >= 2 }
    private var activePoints: [DataPoint] { showDistance ? distancePoints : durationPoints }

    private var longestValue: Double { activePoints.map(\.value).max() ?? 0 }
    private var lastValue: Double    { activePoints.last?.value ?? 0 }
    private var yMin: Double         { (activePoints.map(\.value).min() ?? 0) * 0.9 }
    private var yMax: Double         { longestValue * 1.1 }

    private var spansMultipleYears: Bool {
        guard let first = activePoints.first?.date, let last = activePoints.last?.date else { return false }
        return Calendar.current.component(.year, from: first) != Calendar.current.component(.year, from: last)
    }

    private var unit: String { showDistance ? "km" : "min" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(cardioType)
                    .font(.jost(.bold, size: 13))
                    .kerning(2)
                    .foregroundStyle(Color.historyAccent)

                Spacer()

                if hasDistanceData {
                    HStack(spacing: 16) {
                        Button("TIME") { withAnimation(.easeInOut(duration: 0.2)) { showDistance = false } }
                            .font(.jost(showDistance ? .regular : .semibold, size: 12))
                            .kerning(1.5)
                            .foregroundStyle(showDistance ? Color(.secondaryLabel) : Color.historyAccent)

                        Button("DISTANCE") { withAnimation(.easeInOut(duration: 0.2)) { showDistance = true } }
                            .font(.jost(showDistance ? .semibold : .regular, size: 12))
                            .kerning(1.5)
                            .foregroundStyle(showDistance ? Color.historyAccent : Color(.secondaryLabel))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            if activePoints.count < 2 {
                ChartEmptyState(isEmpty: activePoints.isEmpty)
            } else {
                Chart(activePoints) { point in
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("Värde", point.value)
                    )
                    .foregroundStyle(Color.historyAccent)

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value("Värde", point.value)
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
                    statBlock(label: "LONGEST", value: formatWeight(longestValue), unit: unit, alignment: .leading)
                    statBlock(label: "LATEST", value: formatWeight(lastValue), unit: unit, alignment: .center)
                    statBlock(label: "SESSIONS", value: "\(activePoints.count)", alignment: .trailing)
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
