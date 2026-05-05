import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme

    private var coachImageName: String {
        let gender = AuthService.shared.currentUser?.gender ?? ""
        return gender == "male" ? "CoachMale" : "CoachFemale"
    }

    private var coachTabIcon: UIImage {
        let size: CGFloat = 24
        let img = UIImage(named: coachImageName) ?? UIImage(systemName: "person.circle.fill")!
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let circular = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            UIBezierPath(ovalIn: rect).addClip()
            img.draw(in: rect)
        }
        return circular.withRenderingMode(.alwaysOriginal)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            JournalView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    Text("Log")
                }
                .tag(1)

            ReportsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    Text("Insights")
                }
                .tag(2)

            CoachChatView()
                .tabItem {
                    Image(uiImage: coachTabIcon)
                    Text("AI Coach")
                }
                .tag(3)

            CommunityView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.3.fill" : "person.3")
                    Text("Community")
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
        .onReceive(NotificationCenter.default.publisher(for: .switchToReportsTab)) { _ in
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
