import UserNotifications
import SwiftData

struct ReminderManager {
    static let shared = ReminderManager()

    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "exercis.reminder."

    func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
        return settings.authorizationStatus == .authorized
    }

    // Schedules weekly reminders on the given weekdays at the given hour/minute.
    // Cancels all existing reminders first.
    func schedule(weekdays: Set<Int>, hour: Int, minute: Int) async {
        await cancel()
        guard !weekdays.isEmpty else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to train")
        content.body = String(localized: "Open Exercis and log your session.")
        content.sound = .default

        for weekday in weekdays {
            var comps = DateComponents()
            comps.weekday = weekday
            comps.hour = hour
            comps.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifierPrefix + "\(weekday)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancel() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Returns the hour and minute from the most recent workout start time.
    // Falls back to 17:00 if no history exists.
    static func suggestedTime(from sessions: [WorkoutSession]) -> (hour: Int, minute: Int) {
        guard let latest = sessions.sorted(by: { $0.startDate > $1.startDate }).first else {
            return (17, 0)
        }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: latest.startDate)
        return (comps.hour ?? 17, comps.minute ?? 0)
    }
}
