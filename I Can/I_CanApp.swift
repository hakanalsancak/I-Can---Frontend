import SwiftUI
import Firebase

// MARK: - Jailbreak Detection

private func isDeviceJailbroken() -> Bool {
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

    @State private var appearanceManager = AppearanceManager.shared
    @State private var showJailbreakWarning = isDeviceJailbroken()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceManager.current.colorScheme)
                .task {
                    try? await SubscriptionService.shared.checkStatus()
                    await SubscriptionService.shared.listenForTransactions()
                }
                .onAppear {
                    AnalyticsManager.log("app_opened")
                }
                .alert("Security Warning", isPresented: $showJailbreakWarning) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("This device appears to be jailbroken. Running I Can on a compromised device may expose your data and account to security risks.")
                }
        }
    }
}
