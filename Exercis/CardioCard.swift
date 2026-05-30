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
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.trailing, 4)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Ta bort pass")
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, isExpanded ? 8 : 12)
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
        }
        .sheet(isPresented: $showEffortChart) {
            CardioEffortChartSheet(cardioType: session.cardioType)
                .presentationDetents([.medium, .large])
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

            Button(session.cardioType) {
                chartType = IdentifiableString(id: session.cardioType)
            }
            .buttonStyle(.plain)
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundColor(Color.historyAccent)

            HStack(spacing: 12) {
                Text("\(formatWeight(session.durationMinutes)) min")
                    .font(.jost(.regular, size: 14))
                    .foregroundColor(Color(.secondaryLabel))
                if let km = session.distanceKm, km > 0 {
                    Text("\(formatWeight(km)) km")
                        .font(.jost(.regular, size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
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
