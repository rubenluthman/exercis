import SwiftUI

struct RotationCard: View {
    let rotation: ProgramRotation
    let allPrograms: [WorkoutProgram]
    var hasDraft: Bool = false

    private let letters = ["A", "B", "C", "D", "E", "F"]

    private var nextProgram: WorkoutProgram? {
        guard !rotation.programIds.isEmpty else { return nil }
        let id = rotation.programIds[rotation.nextIndex]
        return allPrograms.first { $0.id.uuidString == id }
    }

    private var accent: Color {
        nextProgram.map { Color($0.colorName) } ?? Color(.secondaryLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(height: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(rotation.name.uppercased())
                    .font(.jost(.bold, size: 15))
                    .kerning(1.5)
                    .foregroundStyle(accent)
                    .lineLimit(2)

                if let next = nextProgram {
                    HStack(spacing: 6) {
                        Text(hasDraft ? "CONTINUE" : "NEXT")
                            .font(.jost(.medium, size: 11))
                            .kerning(1.5)
                            .foregroundStyle(Color(.secondaryLabel))
                        Text(next.name.uppercased())
                            .font(.jost(.medium, size: 11))
                            .kerning(1.5)
                            .foregroundStyle(accent)
                    }
                }

                HStack(spacing: 4) {
                    ForEach(Array(rotation.programIds.enumerated()), id: \.offset) { i, _ in
                        let isNext = i == rotation.nextIndex
                        let letter = i < letters.count ? letters[i] : "\(i + 1)"
                        Text(letter)
                            .font(.jost(.semibold, size: 11))
                            .kerning(1)
                            .foregroundStyle(isNext ? accent : Color(.tertiaryLabel))
                        if i < rotation.programIds.count - 1 {
                            Text("·")
                                .font(.jost(.regular, size: 11))
                                .foregroundStyle(Color(.quaternaryLabel))
                        }
                    }
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
