import SwiftUI
import Firebase
import UserNotifications

// MARK: - Jailbreak Detection

private nonisolated func isDeviceJailbroken() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    let suspiciousPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/",
    ]
    if suspiciousPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
        return true
    }
    // Try writing outside the sandbox
    let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
    do {
        try "jailbreak".write(toFile: testPath, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(atPath: testPath)
        return true
    } catch {
        return false
    }
#endif
}

@main
struct I_CanApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @Environment(\.scenePhase) private var scenePhase
    @State private var appearanceManager = AppearanceManager.shared
    @State private var showJailbreakWarning = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceManager.current.colorScheme)
                .task {
                    if await Task.detached(priority: .utility, operation: { isDeviceJailbroken() }).value {
                        showJailbreakWarning = true
                    }
                    await SubscriptionService.shared.syncEntitlements()
                    await SubscriptionService.shared.listenForTransactions()
                }
                .onAppear {
                    AnalyticsManager.log("app_opened")
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        UNUserNotificationCenter.current().setBadgeCount(0)
                    }
                }
                .alert("Security Warning", isPresented: $showJailbreakWarning) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("This device appears to be jailbroken. Running I Can on a compromised device may expose your data and account to security risks.")
                }
        }
    }
}
