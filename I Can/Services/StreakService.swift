import Foundation

@MainActor
@Observable
final class StreakService {
    static let shared = StreakService()

    func getStreak() async throws -> StreakInfo {
        try await APIClient.shared.request(APIEndpoints.Streaks.base)
    }

    private init() {}
}
