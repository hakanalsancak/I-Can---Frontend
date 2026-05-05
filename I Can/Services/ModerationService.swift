import Foundation

enum ReportReason: String, CaseIterable, Identifiable {
    case spam, harassment, hate, sexual, self_harm, false_info, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .hate: return "Hate or violence"
        case .sexual: return "Sexual content"
        case .self_harm: return "Self-harm"
        case .false_info: return "False information"
        case .other: return "Other"
        }
    }
}

@MainActor
@Observable
final class ModerationService {
    static let shared = ModerationService()

    /// Local set of post / user ids the current user has chosen to hide. Posts hidden
    /// here will be filtered out client-side until refresh. Persisted across launches.
    private(set) var hiddenPostIds: Set<String> = []
    private(set) var blockedUserIds: Set<String> = []

    private let hiddenPostsKey = "community.hiddenPosts"

    private init() {
        if let arr = UserDefaults.standard.stringArray(forKey: hiddenPostsKey) {
            hiddenPostIds = Set(arr)
        }
    }

    func hidePost(_ id: String) {
        hiddenPostIds.insert(id)
        UserDefaults.standard.set(Array(hiddenPostIds), forKey: hiddenPostsKey)
    }

    func report(targetKind: String, targetId: String, reason: ReportReason, note: String? = nil) async throws {
        struct Body: Encodable {
            let targetKind: String
            let targetId: String
            let reason: String
            let note: String?
        }
        struct Resp: Decodable { let id: String; let deduplicated: Bool }
        let _: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.reports,
            method: "POST",
            body: Body(targetKind: targetKind, targetId: targetId, reason: reason.rawValue, note: note)
        )
    }

    @discardableResult
    func block(userId: String) async throws -> Bool {
        struct Resp: Decodable { let blocked: Bool }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.block(userId),
            method: "POST"
        )
        if r.blocked { blockedUserIds.insert(userId) }
        return r.blocked
    }

    @discardableResult
    func unblock(userId: String) async throws -> Bool {
        struct Resp: Decodable { let blocked: Bool }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.block(userId),
            method: "DELETE"
        )
        blockedUserIds.remove(userId)
        return r.blocked
    }
}
