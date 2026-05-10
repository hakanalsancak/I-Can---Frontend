#if canImport(UIKit)
import UIKit
import UserNotifications
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        #endif
        return false
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            try? await NotificationService.shared.registerDeviceToken(token)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("Failed to register for push notifications: \(error.localizedDescription)")
        #endif
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Suppress the foreground banner+sound when the user is already
        // looking at the chat the message belongs to. UN delegate callbacks
        // are delivered on the main thread, so it's safe to read
        // `NotificationService.shared` (which is @MainActor) from here.
        let info = notification.request.content.userInfo
        if let type = info["type"] as? String, type == "community.dm",
           let cid = info["conversationId"] as? String {
            let active = MainActor.assumeIsolated {
                NotificationService.shared.activeConversationId
            }
            if active == cid {
                completionHandler([])
                return
            }
        }
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let payload = response.notification.request.content.userInfo
        if let type = payload["type"] as? String {
            switch type {
            case "report_ready":
                var info: [String: Any] = [:]
                if let id = payload["reportId"] as? String { info["reportId"] = id }
                if let rt = payload["reportType"] as? String { info["reportType"] = rt }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .switchToReportsTab, object: nil)
                    if !info.isEmpty {
                        NotificationCenter.default.post(name: .openReport, object: nil, userInfo: info)
                    }
                }
            case "community.dm":
                var info: [String: Any] = [:]
                if let cid = payload["conversationId"] as? String { info["conversationId"] = cid }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .switchToCommunityTab, object: nil)
                    if !info.isEmpty {
                        NotificationCenter.default.post(name: .openConversation, object: nil, userInfo: info)
                    }
                }
            default:
                break
            }
        }
        completionHandler()
    }
}
#endif
