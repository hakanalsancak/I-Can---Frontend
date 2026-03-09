import Foundation

final class LeaderboardService {
    static let shared = LeaderboardService()
    private init() {}

    func getGlobalLeaderboard() async throws -> LeaderboardResponse {
        try await APIClient.shared.request(APIEndpoints.Leaderboard.global)
    }

    func getCountryLeaderboard(code: String) async throws -> LeaderboardResponse {
        try await APIClient.shared.request(APIEndpoints.Leaderboard.country(code))
    }
}
