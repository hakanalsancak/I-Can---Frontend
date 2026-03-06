import Foundation

@Observable
final class ProfileViewModel {
    var user: User? { AuthService.shared.currentUser }
    var streak: StreakInfo?
    var subscriptionStatus: SubscriptionStatus?
    var isLoading = false
    var showSubscription = false
    var showSettings = false

    var isPremium: Bool { SubscriptionService.shared.isPremium }

    func loadData() async {
        isLoading = true
        async let streakTask: () = loadStreak()
        async let subTask: () = loadSubscription()
        _ = await (streakTask, subTask)
        isLoading = false
    }

    private func loadStreak() async {
        do {
            streak = try await StreakService.shared.getStreak()
        } catch { }
    }

    private func loadSubscription() async {
        do {
            try await SubscriptionService.shared.checkStatus()
            subscriptionStatus = SubscriptionService.shared.subscriptionStatus
        } catch { }
    }

    func signOut() {
        AuthService.shared.signOut()
    }
}
