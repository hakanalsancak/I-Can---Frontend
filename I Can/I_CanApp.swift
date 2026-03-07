import SwiftUI

@main
struct I_CanApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var appearanceManager = AppearanceManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceManager.current.colorScheme)
                .task {
                    await SubscriptionService.shared.checkLocalEntitlement()
                    await SubscriptionService.shared.listenForTransactions()
                }
        }
    }
}
