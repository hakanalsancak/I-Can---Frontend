import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            JournalView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    Text("Journal")
                }
                .tag(1)

            ReportsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    Text("Reports")
                }
                .tag(2)

            CoachChatView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "bubble.left.and.text.bubble.right.fill" : "bubble.left.and.text.bubble.right")
                    Text("AI Coach")
                }
                .tag(3)

            MoreView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "ellipsis.circle.fill" : "ellipsis.circle")
                    Text("More")
                }
                .tag(4)
        }
        .tint(ColorTheme.accent)
        .onAppear {
            requestNotificationPermission()
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToAICoachTab)) { _ in
            withAnimation { selectedTab = 2 }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            #if canImport(UIKit)
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            #endif
        }
    }
}
