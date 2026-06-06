import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]

    @AppStorage("profileName") private var name = ""
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var editingName = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ThinDivider().padding(.top, 8)

            ScrollView {
                VStack(spacing: 40) {
                    avatarSection
                    statsRow
                    streakSection
                    lastSessionSection
                    personalRecordsSection
                    weeklyAverageSection
                }
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear { loadImage() }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                    saveImage(image)
                }
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("PROFILE")
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                avatarView
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(.secondaryLabel))
                            .background(Color.appBackground.clipShape(Circle()))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change profile picture")

            if editingName {
                TextField("Your name", text: $name, onCommit: { editingName = false })
                    .font(.jost(.semibold, size: 20))
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .padding(.horizontal, 48)
            } else {
                Button { editingName = true } label: {
                    Text(name.isEmpty ? "Add name" : name)
                        .font(.jost(.semibold, size: 20))
                        .foregroundStyle(name.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let image = profileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.secondarySystemFill))
                .frame(width: 88, height: 88)
                .overlay {
                    if initials.isEmpty {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(.secondaryLabel))
                    } else {
                        Text(initials)
                            .font(.jost(.semibold, size: 30))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    // MARK: - Top stats row

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            statBlock(label: "STRENGTH", value: "\(workoutSessions.count)", alignment: .leading)
            statBlock(label: "CARDIO",   value: "\(cardioSessions.count)",   alignment: .center)
            statBlock(label: "VOLUME",   value: volumeText.0, unit: volumeText.1, alignment: .center)
            statBlock(label: "CARDIO TIME", value: cardioTimeText.0, unit: cardioTimeText.1, alignment: .trailing)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Streak

    private var streakSection: some View {
        VStack(spacing: 0) {
            ThinDivider()
                .padding(.bottom, 24)

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("STREAK")
                        .font(.jost(.medium, size: 10))
                        .kerning(1.5)
                        .foregroundStyle(Color(.secondaryLabel))

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(currentStreak)")
                            .font(.jost(.black, size: 72))
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.5)

                        Text(currentStreak == 1 ? "day" : "days")
                            .font(.jost(.medium, size: 16))
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(.bottom, 10)
                    }
                }

                Spacer()

                if currentStreak > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("BEST")
                            .font(.jost(.medium, size: 10))
                            .kerning(1.5)
                            .foregroundStyle(Color(.secondaryLabel))
                        Text("\(bestStreak)")
                            .font(.jost(.semibold, size: 22))
                            .foregroundStyle(.primary)
                        Text(currentStreak == bestStreak ? "current best" : "days")
                            .font(.jost(.regular, size: 11))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 24)

            streakDots
                .padding(.top, 20)
        }
    }

    // 14-day dot visualisation
    private var streakDots: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var activeDays = Set<Date>()
        for s in workoutSessions { activeDays.insert(cal.startOfDay(for: s.date)) }
        for s in cardioSessions   { activeDays.insert(cal.startOfDay(for: s.date)) }

        let days: [Date] = (0..<14).reversed().map {
            cal.date(byAdding: .day, value: -$0, to: today)!
        }

        return HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                let active = activeDays.contains(day)
                let isToday = day == today
                RoundedRectangle(cornerRadius: 3)
                    .fill(active ? Color.historyAccent : Color(.systemFill))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .overlay(
                        isToday ?
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color.historyAccent.opacity(0.4), lineWidth: 1)
                        : nil
                    )
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Last session

    private var lastSessionSection: some View {
        VStack(spacing: 0) {
            ThinDivider()
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 14) {
                Text("LAST SESSION")
                    .font(.jost(.medium, size: 10))
                    .kerning(1.5)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.horizontal, 24)

                if let entry = latestEntry {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.jost(.semibold, size: 18))
                                .foregroundStyle(.primary)
                            Text(entry.subtitle)
                                .font(.jost(.regular, size: 13))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(entry.relativeDate)
                                .font(.jost(.regular, size: 13))
                                .foregroundStyle(Color(.secondaryLabel))
                            Text(entry.detailLine)
                                .font(.jost(.regular, size: 12))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    Text("No sessions logged yet.")
                        .font(.jost(.regular, size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - Personal records

    private var personalRecordsSection: some View {
        VStack(spacing: 0) {
            ThinDivider()
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 16) {
                Text("PERSONAL RECORDS")
                    .font(.jost(.medium, size: 10))
                    .kerning(1.5)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.horizontal, 24)

                let records = topPersonalRecords
                if records.isEmpty {
                    Text("Log some strength sessions to see your records.")
                        .font(.jost(.regular, size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(records.enumerated()), id: \.offset) { i, record in
                            HStack(spacing: 0) {
                                Text("\(i + 1)")
                                    .font(.jost(.medium, size: 11))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .frame(width: 20, alignment: .leading)

                                Text(record.name)
                                    .font(.jost(.regular, size: 14))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer()

                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text(formatWeight(record.e1rm))
                                        .font(.jost(.semibold, size: 17))
                                        .foregroundStyle(Color.historyAccent)
                                    Text("kg")
                                        .font(.jost(.regular, size: 11))
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)

                            if i < records.count - 1 {
                                ThinDivider().padding(.leading, 24 + 20)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weekly average

    private var weeklyAverageSection: some View {
        VStack(spacing: 0) {
            ThinDivider()
                .padding(.bottom, 24)

            HStack(alignment: .top, spacing: 0) {
                weeklyStatBlock(
                    label: "AVG / WEEK",
                    value: String(format: "%.1f", weeklyAverage),
                    unit: "sessions",
                    alignment: .leading
                )
                weeklyStatBlock(
                    label: "THIS WEEK",
                    value: "\(sessionsThisWeek)",
                    unit: sessionsThisWeek == 1 ? "session" : "sessions",
                    alignment: .center
                )
                weeklyStatBlock(
                    label: "BEST WEEK",
                    value: "\(bestWeek)",
                    unit: bestWeek == 1 ? "session" : "sessions",
                    alignment: .trailing
                )
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func weeklyStatBlock(label: String, value: String, unit: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.jost(.semibold, size: 22))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(unit)
                .font(.jost(.regular, size: 11))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    // MARK: - Computed

    private var totalVolume: Double {
        workoutSessions.reduce(0.0) { t, s in
            t + s.exerciseLogs.reduce(0.0) { lt, l in
                lt + l.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            }
        }
    }

    private var volumeText: (String, String?) {
        guard totalVolume > 0 else { return ("—", nil) }
        if totalVolume >= 1000 { return (formatWeight(totalVolume / 1000), " TON") }
        return (formatWeight(totalVolume), " KG")
    }

    private var totalCardioMinutes: Double {
        cardioSessions.reduce(0.0) { $0 + $1.durationMinutes }
    }

    private var cardioTimeText: (String, String?) {
        guard totalCardioMinutes > 0 else { return ("—", nil) }
        return (formatWeight(totalCardioMinutes / 60), " H")
    }

    private var trainingDays: Set<Date> {
        let cal = Calendar.current
        var days = Set<Date>()
        for s in workoutSessions { days.insert(cal.startOfDay(for: s.date)) }
        for s in cardioSessions   { days.insert(cal.startOfDay(for: s.date)) }
        return days
    }

    private var currentStreak: Int { computeCurrentStreak(days: trainingDays) }
    private var bestStreak: Int    { computeBestStreak(days: trainingDays) }

    private struct SessionEntry {
        let title: String
        let subtitle: String
        let relativeDate: String
        let detailLine: String
    }

    private var latestEntry: SessionEntry? {
        let lastW = workoutSessions.first
        let lastC = cardioSessions.first

        func relDate(_ d: Date) -> String {
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: d), to: Calendar.current.startOfDay(for: Date())).day ?? 0
            if days == 0 { return String(localized: "Today") }
            if days == 1 { return String(localized: "Yesterday") }
            return "\(days) days ago"
        }

        if let w = lastW, let c = lastC {
            if w.date >= c.date {
                return SessionEntry(
                    title: w.programName ?? String(localized: "Strength"),
                    subtitle: String(localized: "\(w.exerciseLogs.count) exercises"),
                    relativeDate: relDate(w.date),
                    detailLine: w.date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "sv_SE")))
                )
            } else {
                return SessionEntry(
                    title: CardioType(rawValue: c.cardioType)?.displayName ?? c.cardioType,
                    subtitle: formatWeight(c.durationMinutes) + " min",
                    relativeDate: relDate(c.date),
                    detailLine: c.date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "sv_SE")))
                )
            }
        } else if let w = lastW {
            return SessionEntry(
                title: w.programName ?? String(localized: "Strength"),
                subtitle: String(localized: "\(w.exerciseLogs.count) exercises"),
                relativeDate: relDate(w.date),
                detailLine: w.date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "sv_SE")))
            )
        } else if let c = lastC {
            return SessionEntry(
                title: CardioType(rawValue: c.cardioType)?.displayName ?? c.cardioType,
                subtitle: formatWeight(c.durationMinutes) + " min",
                relativeDate: relDate(c.date),
                detailLine: c.date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "sv_SE")))
            )
        }
        return nil
    }

    private struct PREntry {
        let name: String
        let e1rm: Double
    }

    private var topPersonalRecords: [PREntry] {
        var best: [String: Double] = [:]
        for session in workoutSessions {
            for log in session.exerciseLogs {
                for set in log.sets {
                    guard set.reps > 0, set.weight > 0 else { continue }
                    let e1rm = epleyE1RM(weight: set.weight, reps: set.reps)
                    if e1rm > (best[log.name] ?? 0) {
                        best[log.name] = e1rm
                    }
                }
            }
        }
        return best
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { PREntry(name: ExerciseDef.find(name: $0.key)?.displayName ?? $0.key, e1rm: $0.value) }
    }

    private var weeklyAverage: Double {
        guard !workoutSessions.isEmpty || !cardioSessions.isEmpty else { return 0 }
        let allDates = workoutSessions.map(\.date) + cardioSessions.map(\.date)
        guard let oldest = allDates.min() else { return 0 }
        let weeks = max(1.0, Date().timeIntervalSince(oldest) / (7 * 86400))
        return Double(workoutSessions.count + cardioSessions.count) / weeks
    }

    private var sessionsThisWeek: Int {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let w = workoutSessions.filter { $0.date >= start }.count
        let c = cardioSessions.filter { $0.date >= start }.count
        return w + c
    }

    private var bestWeek: Int {
        var counts: [Date: Int] = [:]
        let cal = Calendar.current
        func weekStart(_ d: Date) -> Date {
            cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: d))!
        }
        for s in workoutSessions { counts[weekStart(s.date), default: 0] += 1 }
        for s in cardioSessions   { counts[weekStart(s.date), default: 0] += 1 }
        return counts.values.max() ?? 0
    }

    // MARK: - Shared stat block

    @ViewBuilder
    private func statBlock(label: String, value: String, unit: String? = nil, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.jost(.semibold, size: 22))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let unit {
                    Text(unit)
                        .font(.jost(.semibold, size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    // MARK: - Image persistence

    private func imageURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile.jpg")
    }

    private func saveImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imageURL())
        }
    }

    private func loadImage() {
        if let data = try? Data(contentsOf: imageURL()),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }
}
