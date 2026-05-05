import Foundation

@MainActor
@Observable
final class DMService {
    static let shared = DMService()

    private(set) var conversations: [DMConversation] = []
    private(set) var isLoadingInbox = false

    private init() {}

    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    func loadInbox() async throws {
        if isLoadingInbox { return }
        isLoadingInbox = true
        defer { isLoadingInbox = false }
        let page: DMConversationsPage = try await APIClient.shared.request(
            APIEndpoints.Community.conversations
        )
        conversations = page.items
    }

    @discardableResult
    func openConversation(with userId: String) async throws -> String {
        struct Body: Encodable { let recipientId: String }
        struct Resp: Decodable { let id: String; let isNew: Bool }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.conversations,
            method: "POST",
            body: Body(recipientId: userId)
        )
        return r.id
    }

    func loadMessages(conversationId: String, cursor: String? = nil, limit: Int = 50) async throws -> DMMessagesPage {
        var endpoint = APIEndpoints.Community.conversation(conversationId) + "?limit=\(limit)"
        if let cursor, let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&cursor=\(encoded)"
        }
        return try await APIClient.shared.request(endpoint)
    }

    func send(conversationId: String, body: String) async throws -> DMMessage {
        struct Body: Encodable { let body: String }
        let m: DMMessage = try await APIClient.shared.request(
            APIEndpoints.Community.sendMessage(conversationId),
            method: "POST",
            body: Body(body: body)
        )
        return m
    }

    func markRead(conversationId: String) async {
        struct Resp: Decodable { let lastReadAt: String? }
        do {
            let _: Resp = try await APIClient.shared.request(
                APIEndpoints.Community.markRead(conversationId),
                method: "POST"
            )
            if let i = conversations.firstIndex(where: { $0.id == conversationId }) {
                let c = conversations[i]
                conversations[i] = DMConversation(
                    id: c.id, isGroup: c.isGroup, title: c.title,
                    isRequest: false,
                    lastMessageAt: c.lastMessageAt,
                    lastReadAt: ISO8601DateFormatter().string(from: Date()),
                    unreadCount: 0,
                    other: c.other,
                    lastMessage: c.lastMessage
                )
            }
        } catch {
            // silent
        }
    }
}
