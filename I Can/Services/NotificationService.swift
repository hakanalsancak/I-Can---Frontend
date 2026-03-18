import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private static let streakReminderPrefix = "streak-reminder"

    private let reminderMessages = [
        ("Don't break the chain!", "You haven't logged today. Keep your streak alive."),
        ("Your streak is waiting!", "A quick 2-minute log keeps your momentum going."),
        ("Champions show up daily.", "Log your performance before the day ends."),
        ("Stay consistent.", "Your future self will thank you for logging today."),
        ("One entry. Two minutes.", "Don't let today be the day your streak resets."),
        ("You've come this far.", "Log now and keep your streak strong."),
    ]

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func registerDeviceToken(_ token: String) async throws {
        struct TokenRequest: Encodable { let token: String }
        struct TokenResponse: Decodable { let success: Bool? }
        let _: TokenResponse = try await APIClient.shared.request(
            APIEndpoints.Notifications.deviceToken,
            method: "POST",
            body: TokenRequest(token: token)
        )
    }

    func updatePreferences(frequency: Int) async throws {
        struct PrefRequest: Encodable { let notificationFrequency: Int }
        let _: NotificationPrefResponse = try await APIClient.shared.request(
            APIEndpoints.Notifications.preferences,
            method: "PUT",
            body: PrefRequest(notificationFrequency: frequency)
        )
    }

    /// Schedules streak reminders for the next 7 days at 8 PM, each with a different random message.
    func scheduleStreakReminder() {
        let center = UNUserNotificationCenter.current()
        cancelStreakReminder()

        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let pick = reminderMessages[Int.random(in: 0..<reminderMessages.count)]

            let content = UNMutableNotificationContent()
            content.title = pick.0
            content.body = pick.1
            content.sound = .default

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            dateComponents.hour = 20
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Self.streakReminderPrefix)-\(dayOffset)",
                content: content,
                trigger: trigger
            )

            center.add(request) { _ in }
        }
    }

    /// Cancels all pending streak reminders (called after the user logs their entry).
    func cancelStreakReminder() {
        let ids = (0..<7).map { "\(Self.streakReminderPrefix)-\($0)" }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    private init() {}
}

struct NotificationPrefResponse: Codable {
    let notificationFrequency: Int
}
