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
                    Image(systemName: selectedTab == 2 ? "brain.fill" : "brain")
                    Text("AI Coach")
                }
                .tag(2)

            FriendsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.2.fill" : "person.2")
                    Text("Friends")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
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
