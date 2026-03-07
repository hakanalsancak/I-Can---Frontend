import SwiftUI

@main
struct I_CanApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    await SubscriptionService.shared.checkLocalEntitlement()
                    await SubscriptionService.shared.listenForTransactions()
                }
        }
    }
}
