import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private static let streakReminderPrefix = "streak-reminder"
    private static let motivationalPrefix = "motivational"

    private let reminderMessages = [
        ("Don't break the chain!", "You haven't logged today. Keep your streak alive."),
        ("Your streak is waiting!", "A quick 2-minute log keeps your momentum going."),
        ("Champions show up daily.", "Log your performance before the day ends."),
        ("Stay consistent.", "Your future self will thank you for logging today."),
        ("One entry. Two minutes.", "Don't let today be the day your streak resets."),
        ("You've come this far.", "Log now and keep your streak strong."),
    ]

    private let motivationalQuotes = [
        "I can push through when it gets hard.",
        "I can stay focused under pressure.",
        "I can turn mistakes into lessons.",
        "I can give 100% every single day.",
        "I can control my effort.",
        "I can stay disciplined when no one is watching.",
        "I can be better than yesterday.",
        "I can rise after every fall.",
        "I can trust my preparation.",
        "I can silence the doubt.",
        "I can outwork the competition.",
        "I can show up when it matters most.",
        "I can stay calm in the storm.",
        "I can embrace the grind.",
        "I can lead by example.",
        "I can keep going when others quit.",
        "I can earn it every day.",
        "I can handle the pressure.",
        "I can find a way.",
        "I can be relentless.",
        "I can stay patient with my progress.",
        "I can commit fully to my goals.",
        "I can choose discipline over comfort.",
        "I can compete with myself.",
        "I can overcome any obstacle.",
        "I can finish stronger than I started.",
        "I can take the next step.",
        "I can do the work nobody sees.",
        "I can be consistent day after day.",
        "I can believe in my abilities.",
        "I can recover and come back stronger.",
        "I can focus on what I control.",
        "I can block out distractions.",
        "I can set the standard.",
        "I can prove it on the field.",
        "I can deliver when the stakes are high.",
        "I can build unshakeable confidence.",
        "I can embrace the challenge.",
        "I can fuel my body for performance.",
        "I can learn from every rep.",
        "I can turn fear into fuel.",
        "I can adapt to any situation.",
        "I can be mentally tough.",
        "I can stay locked in.",
        "I can win the day.",
        "I can play without fear.",
        "I can thrive in adversity.",
        "I can control my attitude.",
        "I can chase greatness.",
        "I can trust my training.",
    ]

    /// Hours at which motivational notifications fire based on frequency (1x, 2x, 3x).
    private let motivationalHours: [[Int]] = [
        [],           // 0 = none
        [9],          // 1x = 9 AM
        [9, 15],      // 2x = 9 AM, 3 PM
        [9, 13, 18],  // 3x = 9 AM, 1 PM, 6 PM
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

    // MARK: - Motivational Quote Notifications

    /// Schedules motivational quote notifications for the next 7 days based on the user's frequency preference.
    /// frequency: 0 = none, 1 = 1x/day, 2 = 2x/day, 3 = 3x/day
    func scheduleMotivationalQuotes(frequency: Int) {
        let center = UNUserNotificationCenter.current()
        cancelMotivationalQuotes()

        let clamped = min(max(frequency, 0), 3)
        guard clamped > 0 else { return }

        let hours = motivationalHours[clamped]
        let calendar = Calendar.current
        let now = Date()
        var usedIndices = Set<Int>()

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            for (slotIndex, hour) in hours.enumerated() {
                // Pick a unique quote for each notification slot
                var quoteIndex: Int
                repeat {
                    quoteIndex = Int.random(in: 0..<motivationalQuotes.count)
                } while usedIndices.contains(quoteIndex) && usedIndices.count < motivationalQuotes.count
                usedIndices.insert(quoteIndex)

                let content = UNMutableNotificationContent()
                content.title = "I Can"
                content.body = motivationalQuotes[quoteIndex]
                content.sound = .default

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                dateComponents.hour = hour
                dateComponents.minute = 0

                // Skip if this time has already passed today
                if dayOffset == 0,
                   let fireDate = calendar.date(from: dateComponents),
                   fireDate <= now {
                    continue
                }

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let identifier = "\(Self.motivationalPrefix)-\(dayOffset)-\(slotIndex)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request) { _ in }
            }
        }
    }

    /// Cancels all pending motivational quote notifications.
    func cancelMotivationalQuotes() {
        // 7 days x max 3 slots
        var ids: [String] = []
        for day in 0..<7 {
            for slot in 0..<3 {
                ids.append("\(Self.motivationalPrefix)-\(day)-\(slot)")
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Streak Reminder

    /// Schedules streak reminders for the next 7 days at 8 PM, each with a different random message.
    /// - Parameter skipToday: When true, skips scheduling for today (user already logged).
    func scheduleStreakReminder(skipToday: Bool = false) {
        let center = UNUserNotificationCenter.current()
        cancelStreakReminder()

        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<7 {
            // Skip today entirely if user already logged
            if dayOffset == 0 && skipToday { continue }

            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let pick = reminderMessages[Int.random(in: 0..<reminderMessages.count)]

            let content = UNMutableNotificationContent()
            content.title = pick.0
            content.body = pick.1
            content.sound = .default

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            dateComponents.hour = 20
            dateComponents.minute = 0

            // Skip if 8 PM already passed today
            if dayOffset == 0,
               let fireDate = calendar.date(from: dateComponents),
               fireDate <= today {
                continue
            }

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

    // MARK: - Schedule All

    /// Reschedules all local notifications based on current user state.
    /// Call this on app launch and after settings changes.
    /// Note: Motivational quotes are sent exclusively via backend push (APNS),
    /// so only streak reminders are scheduled locally.
    func scheduleAllNotifications(frequency: Int, hasLoggedToday: Bool) {
        cancelMotivationalQuotes()
        scheduleStreakReminder(skipToday: hasLoggedToday)
    }

    private init() {}
}

struct NotificationPrefResponse: Codable {
    let notificationFrequency: Int
}
