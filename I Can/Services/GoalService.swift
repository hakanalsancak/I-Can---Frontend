import Foundation

@Observable
final class GoalService {
    static let shared = GoalService()

    func getGoals(type: String? = nil) async throws -> [Goal] {
        var endpoint = APIEndpoints.Goals.base
        if let type { endpoint += "?type=\(type)" }
        let response: GoalsResponse = try await APIClient.shared.request(endpoint)
        return response.goals
    }

    func createGoal(_ request: CreateGoalRequest) async throws -> Goal {
        try await APIClient.shared.request(
            APIEndpoints.Goals.base, method: "POST", body: request
        )
    }

    func updateGoal(id: String, _ request: UpdateGoalRequest) async throws -> Goal {
        try await APIClient.shared.request(
            APIEndpoints.Goals.byId(id), method: "PUT", body: request
        )
    }

    func deleteGoal(id: String) async throws {
        let _: MessageResponse = try await APIClient.shared.request(
            APIEndpoints.Goals.byId(id), method: "DELETE"
        )
    }

    private init() {}
}

struct MessageResponse: Codable {
    let message: String
}
