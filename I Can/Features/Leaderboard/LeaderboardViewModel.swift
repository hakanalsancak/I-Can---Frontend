import Foundation

@Observable
final class LeaderboardViewModel {
    var globalEntries: [LeaderboardEntry] = []
    var countryEntries: [LeaderboardEntry] = []
    var myGlobalRank: Int?
    var myCountryRank: Int?
    var myStreak: Int = 0
    var isLoadingGlobal = false
    var isLoadingCountry = false
    var errorMessage: String?

    var userCountryCode: String {
        AuthService.shared.currentUser?.country
            ?? Locale.current.region?.identifier
            ?? "US"
    }

    func loadGlobal() async {
        isLoadingGlobal = true
        errorMessage = nil
        do {
            let response = try await LeaderboardService.shared.getGlobalLeaderboard()
            globalEntries = response.leaderboard
            myGlobalRank = response.myRank
            myStreak = response.myStreak
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingGlobal = false
    }

    func loadCountry() async {
        isLoadingCountry = true
        do {
            let response = try await LeaderboardService.shared.getCountryLeaderboard(code: userCountryCode)
            countryEntries = response.leaderboard
            myCountryRank = response.myRank
        } catch {
            // Country may not be set yet
        }
        isLoadingCountry = false
    }

    func loadAll() async {
        await loadGlobal()
        await loadCountry()
    }
}
