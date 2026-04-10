import Foundation

final class FriendService {
    static let shared = FriendService()

    private var cachedFriends: [AthleteProfile] = []
    private var friendsFetchedAt: Date?
    private let cacheMaxAge: TimeInterval = 60

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

    func getFriends(forceRefresh: Bool = false) async throws -> [AthleteProfile] {
        if !forceRefresh,
           let fetchedAt = friendsFetchedAt, Date().timeIntervalSince(fetchedAt) < cacheMaxAge,
           !cachedFriends.isEmpty {
            return cachedFriends
        }
        let friends: [AthleteProfile] = try await APIClient.shared.request(APIEndpoints.Friends.base)
        cachedFriends = friends
        friendsFetchedAt = Date()
        return friends
    }

    func invalidateFriendsCache() {
        friendsFetchedAt = nil
    }

    func getPendingRequests() async throws -> [FriendRequest] {
        try await APIClient.shared.request(APIEndpoints.Friends.requests)
    }

    func getSentRequests() async throws -> [SentFriendRequest] {
        try await APIClient.shared.request(APIEndpoints.Friends.sentRequests)
    }

    func sendFriendRequest(receiverId: String) async throws -> SendFriendRequestResponse {
        let body = ["receiverId": receiverId]
        let result: SendFriendRequestResponse = try await APIClient.shared.request(
            APIEndpoints.Friends.sendRequest, method: "POST", body: body
        )
        invalidateFriendsCache()
        return result
    }

    func respondToRequest(id: String, action: String) async throws -> FriendActionResponse {
        let body = ["action": action]
        let result: FriendActionResponse = try await APIClient.shared.request(
            APIEndpoints.Friends.respondRequest(id), method: "PUT", body: body
        )
        invalidateFriendsCache()
        return result
    }

    func cancelRequest(id: String) async throws {
        let _: FriendActionResponse = try await APIClient.shared.request(
            APIEndpoints.Friends.cancelRequest(id), method: "DELETE"
        )
        invalidateFriendsCache()
    }

    func removeFriend(id: String) async throws {
        let _: FriendActionResponse = try await APIClient.shared.request(
            APIEndpoints.Friends.remove(id), method: "DELETE"
        )
        invalidateFriendsCache()
    }

    func getFriendProfile(id: String) async throws -> AthleteProfile {
        try await APIClient.shared.request(APIEndpoints.Friends.profile(id))
    }
}
