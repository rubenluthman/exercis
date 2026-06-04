import SwiftUI
import SwiftData

#Preview {
    let session = CardioSession(date: Date(), durationMinutes: 45)
    return CardioCard(session: session, isExpanded: true, onTap: {}, onDelete: {})
        .background(Color.appBackground)
        .modelContainer(for: CardioSession.self, inMemory: true)
}

private struct IdentifiableString: Identifiable {
    let id: String
}

struct CardioCard: View {
    let session: CardioSession
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var chartType: IdentifiableString? = nil
    @State private var showEffortChart = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    HStack(spacing: 8) {
                        Text(dateText)
                            .font(.jost(.bold, size: 14))
                            .foregroundColor(.primary)
                        Text(timeText)
                            .font(.jost(.regular, size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    if !isExpanded {
                        Image(systemName: "chevron.right")
                            .font(.jost(.medium, size: 10))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.jost(.medium, size: 11))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(width: 44, height: 44, alignment: .trailing)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Ta bort pass")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, isExpanded ? 2 : 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Radera pass", systemImage: "trash")
                }
            }

            if isExpanded {
                expandedContent
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .sheet(item: $chartType) { item in
            CardioChartSheet(cardioType: item.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEffortChart) {
            CardioEffortChartSheet(cardioType: session.cardioType)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let score = session.effortScore {
                Button {
                    showEffortChart = true
                } label: {
                    HStack(spacing: 4) {
                        Text("ANSTRÄNGNING")
                            .font(.jost(.medium, size: 10))
                            .kerning(1.5)
                            .foregroundColor(Color(.secondaryLabel))
                        Text("\(score)/10")
                            .font(.jost(.semibold, size: 10))
                            .kerning(1.5)
                            .foregroundColor(Color.historyAccent)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 4)
            }

            Button((CardioType(rawValue: session.cardioType)?.displayName ?? session.cardioType).uppercased()) {
                chartType = IdentifiableString(id: session.cardioType)
            }
            .buttonStyle(.plain)
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundColor(Color.historyAccent)

            HStack(spacing: 12) {
                Text(durationText)
                    .font(.jost(.regular, size: 14))
                    .foregroundColor(Color(.secondaryLabel))
                if let km = session.distanceKm, km > 0 {
                    Text("\(formatWeight(km)) KM")
                        .font(.jost(.regular, size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 0)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var durationText: String {
        let mins = session.durationMinutes
        if session.cardioType == CardioType.hiking.rawValue && mins >= 60 {
            let h = Int(mins) / 60
            let m = Int(mins) % 60
            return m > 0 ? "\(h) h \(m) min" : "\(h) h"
        }
        return "\(formatWeight(mins)) min"
    }

    private var dateText: String {
        let sv = Locale(identifier: "sv_SE")
        let weekday = session.date.formatted(.dateTime.weekday(.wide).locale(sv))
        let dayMonth = session.date.formatted(.dateTime.day().month(.wide).locale(sv))
        return "\(weekday.capitalized) \(dayMonth)"
    }

    private var timeText: String {
        session.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(Locale(identifier: "sv_SE")))
    }
}
