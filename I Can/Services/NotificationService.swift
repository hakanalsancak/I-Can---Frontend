import Foundation
import UserNotifications

@Observable
final class NotificationService {
    static let shared = NotificationService()

    private static let streakReminderID = "streak-reminder"

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
        let _: MessageResponse = try await APIClient.shared.request(
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

    /// Schedules a daily 8 PM local notification reminding the user to log.
    func scheduleStreakReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.streakReminderID])

        let pick = reminderMessages[Int.random(in: 0..<reminderMessages.count)]

        let content = UNMutableNotificationContent()
        content.title = pick.0
        content.body = pick.1
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.streakReminderID,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Cancels today's streak reminder (called after the user logs their entry).
    func cancelStreakReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.streakReminderID])
    }

    private init() {}
}

struct NotificationPrefResponse: Codable {
    let notificationFrequency: Int
}
