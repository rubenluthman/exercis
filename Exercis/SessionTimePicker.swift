import SwiftUI

struct SessionTimePicker: View {
    @Binding var start: Date
    @Binding var end: Date
    let accent: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TIDPUNKT")
                .font(.jost(.bold, size: 13))
                .kerning(2)
                .foregroundColor(accent)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            ThinDivider()

            HStack {
                Text("START")
                    .font(.jost(.medium, size: 10))
                    .kerning(1.5)
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()
                DatePicker("", selection: $start, in: ...end, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "sv_SE"))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            ThinDivider()

            HStack {
                Text("SLUT")
                    .font(.jost(.medium, size: 10))
                    .kerning(1.5)
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()
                DatePicker("", selection: $end, in: start..., displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "sv_SE"))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            ThinDivider()

            Button("KLAR") { dismiss() }
                .buttonStyle(FilledButtonStyle(accent: accent))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
        .background(Color.appBackground)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(330), .large])
    }
}
