import Foundation

struct CommunityCountResponse: Decodable {
    let count: Int
    let isMember: Bool
}

@MainActor
@Observable
final class CommunityCountService {
    static let shared = CommunityCountService()

    private static let baseCount = 314
    private static let cachedCountKey = "community.cachedCount"
    private static let isMemberKeyPrefix = "community.isMember."

    /// Last count returned by the backend (or `baseCount` on first launch).
    /// Cached only so the card has something to show before the first refresh
    /// completes — the backend is always the source of truth.
    private(set) var count: Int

    /// Whether the currently-bound user has joined. Per-user, so a second
    /// account on the same device sees the Join button until they tap it.
    private(set) var isMember: Bool = false

    private var boundUserId: String?

    private init() {
        let stored = UserDefaults.standard.integer(forKey: Self.cachedCountKey)
        self.count = stored > 0 ? stored : Self.baseCount
    }

    private static func memberKey(for userId: String) -> String {
        isMemberKeyPrefix + userId
    }

    private func persistCount() {
        UserDefaults.standard.set(count, forKey: Self.cachedCountKey)
    }

    /// Rebinds local state to the given user. Safe to call on every view
    /// appearance. `isMember` will be reconciled by the next refresh.
    func bind(userId: String?) {
        boundUserId = userId
        if let userId {
            isMember = UserDefaults.standard.bool(forKey: Self.memberKey(for: userId))
        } else {
            isMember = false
        }
    }

    func refresh() async {
        do {
            let response: CommunityCountResponse = try await APIClient.shared.request(
                APIEndpoints.Community.count
            )
            apply(response)
        } catch {
            // Keep the last known value so the card never shows an error.
        }
    }

    /// Optimistic join: updates UI immediately, then syncs with the backend.
    /// On failure the optimistic +1 is rolled back so the displayed count
    /// stays consistent with what other users see.
    func join() async {
        guard !isMember else { return }
        let previousCount = count
        let previousIsMember = isMember

        isMember = true
        count += 1
        persistCount()
        if let userId = boundUserId {
            UserDefaults.standard.set(true, forKey: Self.memberKey(for: userId))
        }

        struct Empty: Encodable {}
        do {
            let response: CommunityCountResponse = try await APIClient.shared.request(
                APIEndpoints.Community.join,
                method: "POST",
                body: Empty()
            )
            apply(response)
        } catch {
            // Roll back so the user never sees a number that isn't real on the
            // backend. The next tap will retry.
            isMember = previousIsMember
            count = previousCount
            persistCount()
            if let userId = boundUserId {
                UserDefaults.standard.set(previousIsMember, forKey: Self.memberKey(for: userId))
            }
        }
    }

    private func apply(_ response: CommunityCountResponse) {
        isMember = response.isMember
        count = response.count
        persistCount()
        if let userId = boundUserId {
            UserDefaults.standard.set(response.isMember, forKey: Self.memberKey(for: userId))
        }
    }
}
