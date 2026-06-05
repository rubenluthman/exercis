import WidgetKit
import SwiftUI

struct ExercisWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ExercisWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExercisWidgetEntry {
        ExercisWidgetEntry(date: .now, snapshot: WidgetSnapshot(
            streak: 5,
            lastSessionDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            lastSessionProgramName: "Push",
            lastSessionExerciseCount: 5,
            nextProgramName: "Pull",
            nextProgramColorName: "paletteLightBlue"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (ExercisWidgetEntry) -> Void) {
        completion(ExercisWidgetEntry(date: .now, snapshot: WidgetDataStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExercisWidgetEntry>) -> Void) {
        let entry = ExercisWidgetEntry(date: .now, snapshot: WidgetDataStore.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct ExercisWidgetView: View {
    let entry: ExercisWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }

    // MARK: - Small (streak + next program)

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.snapshot.streak)")
                    .font(.system(size: 48, weight: .black, design: .default))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                Text("day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: -4)
            }
            Spacer()
            if let next = entry.snapshot.nextProgramName {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UP NEXT")
                        .font(.system(size: 8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.tertiary)
                    Text(next)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Medium (streak + last session + next program)

    private var mediumView: some View {
        HStack(spacing: 0) {
            // Left: streak
            VStack(alignment: .leading, spacing: 4) {
                Text("STREAK")
                    .font(.system(size: 9, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(.tertiary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(entry.snapshot.streak)")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                    Text("days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .offset(y: -2)
                }
                Spacer()
                if let next = entry.snapshot.nextProgramName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UP NEXT")
                            .font(.system(size: 8, weight: .semibold))
                            .kerning(1.2)
                            .foregroundStyle(.tertiary)
                        Text(next)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accentColor)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 0.5)
                .padding(.vertical, 16)

            // Right: last session
            VStack(alignment: .leading, spacing: 6) {
                Text("LAST SESSION")
                    .font(.system(size: 9, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(.tertiary)

                if let name = entry.snapshot.lastSessionProgramName {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                if let date = entry.snapshot.lastSessionDate {
                    Text(date, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                if entry.snapshot.lastSessionExerciseCount > 0 {
                    Text("\(entry.snapshot.lastSessionExerciseCount) exercises")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
    }

    private var accentColor: Color {
        guard let name = entry.snapshot.nextProgramColorName,
              let pc = ProgramColor(rawValue: name) else {
            return Color.blue
        }
        return pc.color
    }
}

struct ExercisHomeWidget: Widget {
    let kind = "ExercisHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExercisWidgetProvider()) { entry in
            ExercisWidgetView(entry: entry)
        }
        .configurationDisplayName("Exercis")
        .description("Current streak, last session, and next program.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ExercisHomeWidget()
} timeline: {
    ExercisWidgetEntry(date: .now, snapshot: WidgetSnapshot(
        streak: 12,
        lastSessionDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
        lastSessionProgramName: "Push",
        lastSessionExerciseCount: 5,
        nextProgramName: "Pull",
        nextProgramColorName: "paletteGreen"
    ))
}

#Preview(as: .systemMedium) {
    ExercisHomeWidget()
} timeline: {
    ExercisWidgetEntry(date: .now, snapshot: WidgetSnapshot(
        streak: 12,
        lastSessionDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
        lastSessionProgramName: "Push",
        lastSessionExerciseCount: 5,
        nextProgramName: "Pull",
        nextProgramColorName: "paletteGreen"
    ))
}
