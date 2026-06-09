import SwiftUI

struct CardioTypeCard: View {
    let type: CardioType
    let lastDurationMinutes: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.workoutAccent)
                .frame(height: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName.uppercased())
                    .font(.jost(.bold, size: 15))
                    .kerning(1.5)
                    .foregroundStyle(Color.workoutAccent)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let mins = lastDurationMinutes {
                    Text(String(format: String(localized: "LAST: %g MIN"), mins))
                        .font(.jost(.medium, size: 10))
                        .kerning(1.5)
                        .foregroundStyle(Color(.secondaryLabel))
                } else {
                    Text(String(localized: "NO SESSIONS YET"))
                        .font(.jost(.medium, size: 10))
                        .kerning(1.5)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }
}
