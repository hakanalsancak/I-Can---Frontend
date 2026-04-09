import Foundation

@MainActor
@Observable
final class FriendsViewModel {
    var friends: [AthleteProfile] = []
    var pendingRequests: [FriendRequest] = []
    var sentRequests: [SentFriendRequest] = []
    var searchResults: [AthleteProfile] = []
    var searchText: String = ""
    var isLoading = false
    var isSearching = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    var pendingCount: Int { pendingRequests.count }

    func loadAll() async {
        isLoading = true
        async let friendsTask = FriendService.shared.getFriends()
        async let requestsTask = FriendService.shared.getPendingRequests()
        async let sentTask = FriendService.shared.getSentRequests()

        do {
            let (f, r, s) = try await (friendsTask, requestsTask, sentTask)
            friends = f
            pendingRequests = r
            sentRequests = s
        } catch {
            if !Task.isCancelled && (error as? URLError)?.code != .cancelled {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func search(query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        let current = query
        searchTask = Task {
            defer { isSearching = false }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, current == searchText else { return }

            AnalyticsManager.log("friend_search", parameters: ["query_length": current.count])
            do {
                let results = try await FriendService.shared.searchUsers(query: current)
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch {
                guard !Task.isCancelled, (error as? URLError)?.code != .cancelled else { return }
                searchResults = []
                errorMessage = error.localizedDescription
            }
        }
    }

    func sendRequest(to userId: String) async {
        guard let idx = searchResults.firstIndex(where: { $0.id == userId }) else { return }

        let previousStatus = searchResults[idx].friendStatus
        searchResults[idx].friendStatus = "pending"

        do {
            _ = try await FriendService.shared.sendFriendRequest(receiverId: userId)
            AnalyticsManager.log("friend_added", parameters: ["target_user_id": userId])
        } catch {
            searchResults[idx].friendStatus = previousStatus
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            _ = try await FriendService.shared.respondToRequest(id: request.id, action: "accept")
            pendingRequests.removeAll { $0.id == request.id }
            friends.append(request.sender)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        do {
            _ = try await FriendService.shared.respondToRequest(id: request.id, action: "decline")
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelSentRequest(_ request: SentFriendRequest) async {
        do {
            try await FriendService.shared.cancelRequest(id: request.id)
            sentRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friend: AthleteProfile) async {
        do {
            try await FriendService.shared.removeFriend(id: friend.id)
            friends.removeAll { $0.id == friend.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
