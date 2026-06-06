import SwiftUI

private struct WhatsNewEntry: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}

private let entries: [WhatsNewEntry] = [
    WhatsNewEntry(
        icon: "chart.line.uptrend.xyaxis",
        iconColor: .historyAccent,
        title: "Volume chart",
        body: "Tap VOL in any exercise chart to switch between estimated 1RM and total volume per session."
    ),
    WhatsNewEntry(
        icon: "heart.text.square",
        iconColor: .homeAccent,
        title: "Apple Health at onboarding",
        body: "Health permissions are now requested during setup so workouts sync from your very first session."
    ),
    WhatsNewEntry(
        icon: "square.and.arrow.up",
        iconColor: .workoutAccent,
        title: "Export fixed",
        body: "The data export sheet no longer opens blank."
    ),
]

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WHAT'S NEW")
                        .font(.jost(.bold, size: 17))
                        .kerning(2)
                        .foregroundStyle(.primary)
                    Text(appVersion)
                        .font(.jost(.regular, size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: entry.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(entry.iconColor)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title)
                                    .font(.jost(.semibold, size: 15))
                                    .foregroundStyle(.primary)
                                Text(entry.body)
                                    .font(.jost(.regular, size: 14))
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
