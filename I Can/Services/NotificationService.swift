import Foundation
import UserNotifications

@Observable
final class NotificationService {
    static let shared = NotificationService()

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

    private init() {}
}

struct NotificationPrefResponse: Codable {
    let notificationFrequency: Int
}
