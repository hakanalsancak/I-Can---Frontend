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
    private static let deviceCountKey = "community.deviceCount"
    private static let isMemberKeyPrefix = "community.isMember."

    /// Highest count ever observed on this device (across any user). Persisted
    /// so switching accounts on the same phone never makes the number go down.
    private(set) var count: Int

    /// Whether the currently-bound user has joined. Per-user, so a second
    /// account on the same device sees the Join button until they tap it.
    private(set) var isMember: Bool = false

    private var boundUserId: String?

    private init() {
        let stored = UserDefaults.standard.integer(forKey: Self.deviceCountKey)
        self.count = max(stored, Self.baseCount)
    }

    private static func memberKey(for userId: String) -> String {
        isMemberKeyPrefix + userId
    }

    private func persistCount() {
        UserDefaults.standard.set(count, forKey: Self.deviceCountKey)
    }

    /// Rebinds local state to the given user. Safe to call on every view
    /// appearance. The device-wide count is preserved; only `isMember` flips.
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
            // Backend is source of truth for the current user's membership.
            isMember = response.isMember
            if let userId = boundUserId {
                UserDefaults.standard.set(response.isMember, forKey: Self.memberKey(for: userId))
            }
            // Never let a stale response shrink the displayed count.
            if response.count > count {
                count = response.count
                persistCount()
            }
        } catch {
            // Silent fail — keep the last known value so the card never shows an error.
        }
    }

    /// Optimistic join: updates UI immediately, then syncs with the backend.
    /// The +1 is persisted device-wide so the count survives account switches.
    func join() async {
        guard !isMember else { return }
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
            if response.count > count {
                count = response.count
                persistCount()
            }
        } catch {
            // Optimistic state stays — the next refresh will reconcile.
        }
    }
}
