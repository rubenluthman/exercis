import SwiftUI

struct ProgramCard: View {
    let program: WorkoutProgram
    var isSelected: Bool = false
    var showCheckmark: Bool = false

    private var accent: Color { Color(program.colorName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(height: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(program.name.uppercased())
                        .font(.jost(.bold, size: 15))
                        .kerning(1.5)
                        .foregroundStyle(accent)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if showCheckmark {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.jost(.regular, size: 18))
                            .foregroundStyle(isSelected ? accent : Color(.tertiaryLabel))
                    }
                }

                Text("\(program.exercises.count) ÖVNINGAR · \(program.sortedExercises.first?.setCount ?? 3) SET")
                    .font(.jost(.medium, size: 10))
                    .kerning(1.5)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            isSelected
                ? accent.opacity(0.08)
                : Color.appBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
