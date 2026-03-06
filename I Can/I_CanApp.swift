import SwiftUI

@main
struct I_CanApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await SubscriptionService.shared.listenForTransactions()
                }
        }
    }
}
