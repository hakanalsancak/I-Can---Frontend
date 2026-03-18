import Foundation

final class FriendService {
    static let shared = FriendService()
    private init() {}

    func searchUsers(query: String) async throws -> [AthleteProfile] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = APIEndpoints.Friends.search + "?q=\(encoded)"
        #if DEBUG
        print("[FriendService] searchUsers endpoint: \(endpoint)")
        #endif
        do {
            let results: [AthleteProfile] = try await APIClient.shared.request(endpoint)
            #if DEBUG
            print("[FriendService] searchUsers returned \(results.count) results")
            #endif
            return results
        } catch {
            #if DEBUG
            print("[FriendService] searchUsers error: \(error)")
            #endif
            throw error
        }
    }

    func checkUsername(_ username: String) async throws -> UsernameCheck {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        return try await APIClient.shared.request(APIEndpoints.Friends.checkUsername + "?username=\(encoded)", authenticated: false)
    }

    func getFriends() async throws -> [AthleteProfile] {
        try await APIClient.shared.request(APIEndpoints.Friends.base)
    }

    func getPendingRequests() async throws -> [FriendRequest] {
        try await APIClient.shared.request(APIEndpoints.Friends.requests)
    }

    func sendFriendRequest(receiverId: String) async throws -> SendFriendRequestResponse {
        let body = ["receiverId": receiverId]
        return try await APIClient.shared.request(
            APIEndpoints.Friends.sendRequest, method: "POST", body: body
        )
    }

    func respondToRequest(id: String, action: String) async throws -> FriendActionResponse {
        let body = ["action": action]
        return try await APIClient.shared.request(
            APIEndpoints.Friends.respondRequest(id), method: "PUT", body: body
        )
    }

    func cancelRequest(id: String) async throws {
        let _: FriendActionResponse = try await APIClient.shared.request(
            APIEndpoints.Friends.cancelRequest(id), method: "DELETE"
        )
    }

    func removeFriend(id: String) async throws {
        let _: FriendActionResponse = try await APIClient.shared.request(
            APIEndpoints.Friends.remove(id), method: "DELETE"
        )
    }

    func getFriendProfile(id: String) async throws -> AthleteProfile {
        try await APIClient.shared.request(APIEndpoints.Friends.profile(id))
    }
}
