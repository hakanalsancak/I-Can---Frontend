import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            JournalView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Journal")
                }
                .tag(1)

            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(2)

            MentalToolsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Mental")
                }
                .tag(3)

            ReportsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
                .tag(4)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(5)
        }
        .tint(ColorTheme.accent)
        .onAppear {
            requestNotificationPermission()
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
