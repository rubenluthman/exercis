import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Color helper

private extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 6 { hex = "FF" + hex }
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget

struct ExercisLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExercisActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.programName.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                        Text("ÖVNING \(context.state.exerciseIndex + 1)/\(context.state.totalExercises)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("SET \(context.state.setNumber)/\(context.state.totalSets)")
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundStyle(Color(hex: context.attributes.accentHex))
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.exerciseName.uppercased())
                            .font(.system(size: 17, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                        SetDots(
                            setNumber: context.state.setNumber,
                            totalSets: context.state.totalSets,
                            accent: Color(hex: context.attributes.accentHex)
                        )
                    }
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Text(context.state.exerciseName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: context.attributes.accentHex))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 4)
            } compactTrailing: {
                Text("\(context.state.setNumber)/\(context.state.totalSets)")
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color(hex: context.attributes.accentHex))
                    .padding(.trailing, 4)
            } minimal: {
                Text("\(context.state.setNumber)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: context.attributes.accentHex))
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<ExercisActivityAttributes>

    var body: some View {
        let accent = Color(hex: context.attributes.accentHex)
        let state = context.state

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(context.attributes.programName.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("EXERCIS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.secondary)
            }

            Text(state.exerciseName.uppercased())
                .font(.system(size: 22, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: 12) {
                Text("SET \(state.setNumber) / \(state.totalSets)")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(accent)
                SetDots(setNumber: state.setNumber, totalSets: state.totalSets, accent: accent)
                Spacer()
                Text("\(state.exerciseIndex + 1)/\(state.totalExercises)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Set dots

private struct SetDots: View {
    let setNumber: Int
    let totalSets: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...max(1, totalSets), id: \.self) { i in
                Circle()
                    .fill(i <= setNumber ? accent : Color(.tertiaryLabel))
                    .frame(width: 7, height: 7)
            }
        }
    }
}
