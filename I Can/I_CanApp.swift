import SwiftUI
import Firebase

@main
struct I_CanApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var appearanceManager = AppearanceManager.shared

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
        }
    }
}
