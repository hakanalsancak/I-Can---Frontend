import Foundation

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

@MainActor
@Observable
final class DMService {
    static let shared = DMService()

    private(set) var conversations: [DMConversation] = []
    private(set) var isLoadingInbox = false

    private(set) var pinnedIds: Set<String> = []
    private(set) var mutedIds: Set<String> = []
    private(set) var archivedIds: Set<String> = []
    private(set) var hiddenIds: Set<String> = []
    private(set) var manualUnreadIds: Set<String> = []

    private var loadedLocalUserId: String?

    private init() {}

    var totalUnread: Int {
        var total = 0
        for c in conversations {
            if hiddenIds.contains(c.id) { continue }
            if archivedIds.contains(c.id) { continue }
            if mutedIds.contains(c.id) { continue }
            let count = manualUnreadIds.contains(c.id) ? max(c.unreadCount, 1) : c.unreadCount
            total += count
        }
        return total
    }

    var visibleConversations: [DMConversation] {
        conversations.filter { !hiddenIds.contains($0.id) }
    }

    func loadInbox() async throws {
        reloadLocalState()
        if isLoadingInbox { return }
        isLoadingInbox = true
        defer { isLoadingInbox = false }
        let page: DMConversationsPage = try await APIClient.shared.request(
            APIEndpoints.Community.conversations
        )
        conversations = page.items
        prunePersistedState()
    }

    // MARK: - Local conversation state (per-user)

    func reloadLocalState() {
        let uid = AuthService.shared.currentUser?.id ?? "anon"
        if loadedLocalUserId == uid { return }
        loadedLocalUserId = uid
        let d = UserDefaults.standard
        pinnedIds = readSet(d, name: "pinned")
        mutedIds = readSet(d, name: "muted")
        archivedIds = readSet(d, name: "archived")
        hiddenIds = readSet(d, name: "hidden")
        manualUnreadIds = readSet(d, name: "manualUnread")
    }

    func togglePin(_ id: String) {
        if pinnedIds.contains(id) { pinnedIds.remove(id) } else { pinnedIds.insert(id) }
        persist("pinned", pinnedIds)
    }

    func toggleMute(_ id: String) {
        if mutedIds.contains(id) { mutedIds.remove(id) } else { mutedIds.insert(id) }
        persist("muted", mutedIds)
    }

    func setArchived(_ id: String, _ archived: Bool) {
        if archived {
            archivedIds.insert(id)
            pinnedIds.remove(id)
            persist("pinned", pinnedIds)
        } else {
            archivedIds.remove(id)
        }
        persist("archived", archivedIds)
    }

    func setManualUnread(_ id: String, _ unread: Bool) {
        if unread { manualUnreadIds.insert(id) } else { manualUnreadIds.remove(id) }
        persist("manualUnread", manualUnreadIds)
    }

    /// Hides a conversation locally — equivalent to "Delete chat" in WhatsApp.
    /// Backend keeps the thread; if a new message arrives, it'll resurface on next load.
    func hideConversation(_ id: String) {
        hiddenIds.insert(id)
        pinnedIds.remove(id)
        archivedIds.remove(id)
        manualUnreadIds.remove(id)
        persist("pinned", pinnedIds)
        persist("archived", archivedIds)
        persist("manualUnread", manualUnreadIds)
        persist("hidden", hiddenIds)
        conversations.removeAll { $0.id == id }
    }

    /// Drops persisted ids that no longer exist server-side, except `hidden`
    /// which is intentionally sticky so a deleted chat stays gone unless a
    /// new message brings it back (mirrors WhatsApp behavior).
    private func prunePersistedState() {
        let live = Set(conversations.map { $0.id })
        prune(&pinnedIds, live: live, name: "pinned")
        prune(&mutedIds, live: live, name: "muted")
        prune(&archivedIds, live: live, name: "archived")
        prune(&manualUnreadIds, live: live, name: "manualUnread")
    }

    private func prune(_ set: inout Set<String>, live: Set<String>, name: String) {
        let filtered = set.intersection(live)
        if filtered != set {
            set = filtered
            persist(name, set)
        }
    }

    private func readSet(_ d: UserDefaults, name: String) -> Set<String> {
        let key = storageKey(name)
        return Set((d.array(forKey: key) as? [String]) ?? [])
    }

    private func persist(_ name: String, _ set: Set<String>) {
        UserDefaults.standard.set(Array(set), forKey: storageKey(name))
    }

    private func storageKey(_ name: String) -> String {
        let uid = loadedLocalUserId ?? AuthService.shared.currentUser?.id ?? "anon"
        return "dm.local.\(uid).\(name)"
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

    func send(conversationId: String, body: String, replyToMessageId: String? = nil) async throws -> DMMessage {
        struct Body: Encodable {
            let body: String
            let replyToMessageId: String?
        }
        let m: DMMessage = try await APIClient.shared.request(
            APIEndpoints.Community.sendMessage(conversationId),
            method: "POST",
            body: Body(body: body, replyToMessageId: replyToMessageId)
        )
        locallyApplyOutgoing(message: m, conversationId: conversationId)
        return m
    }

    func sendAttachment(
        conversationId: String,
        kind: String,
        attachment: DMAttachmentRef,
        body: String? = nil,
        replyToMessageId: String? = nil
    ) async throws -> DMMessage {
        struct Body: Encodable {
            let body: String?
            let attachmentType: String
            let attachmentRef: DMAttachmentRef
            let replyToMessageId: String?
        }
        let m: DMMessage = try await APIClient.shared.request(
            APIEndpoints.Community.sendMessage(conversationId),
            method: "POST",
            body: Body(body: body, attachmentType: kind, attachmentRef: attachment, replyToMessageId: replyToMessageId)
        )
        locallyApplyOutgoing(message: m, conversationId: conversationId)
        return m
    }

    /// Updates the matching conversation in-memory to reflect a just-sent
    /// message, so the inbox preview stays current without a full network
    /// refetch. Pinned/archived/etc. flags are preserved.
    private func locallyApplyOutgoing(message: DMMessage, conversationId: String) {
        guard let i = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        let c = conversations[i]
        let preview = DMConversationLastMessage(
            senderId: message.senderId,
            body: message.body ?? "",
            createdAt: message.createdAt
        )
        conversations[i] = DMConversation(
            id: c.id,
            isGroup: c.isGroup,
            title: c.title,
            isRequest: false,
            lastMessageAt: message.createdAt,
            lastReadAt: message.createdAt,
            unreadCount: 0,
            other: c.other,
            lastMessage: preview
        )
    }

    /// Uploads bytes to /messages/upload via multipart and returns the Cloudinary URL + metadata.
    func uploadMedia(data: Data, kind: String, mimeType: String, filename: String) async throws -> DMAttachmentRef {
        let token = TokenManager.shared.accessToken ?? ""
        guard let url = URL(string: APIEndpoints.baseURL + APIEndpoints.Community.uploadMedia) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"kind\"\r\n\r\n")
        body.appendString("\(kind)\r\n")
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let session = URLSession.shared
        let (responseData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: responseData, encoding: .utf8) ?? ""
            throw APIError.serverError("Upload failed (\(http.statusCode)): \(msg)")
        }
        struct Resp: Decodable {
            let url: String
            let durationMs: Int?
            let width: Int?
            let height: Int?
        }
        let r = try JSONDecoder().decode(Resp.self, from: responseData)
        return DMAttachmentRef(
            url: r.url,
            durationMs: r.durationMs,
            width: r.width,
            height: r.height
        )
    }

    func deleteMessage(conversationId: String, messageId: String) async throws {
        struct Resp: Decodable { let ok: Bool }
        let _: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.deleteMessage(conversationId, messageId),
            method: "DELETE"
        )
    }

    func markRead(conversationId: String) async {
        struct Resp: Decodable { let lastReadAt: String? }
        do {
            let _: Resp = try await APIClient.shared.request(
                APIEndpoints.Community.markRead(conversationId),
                method: "POST"
            )
            if manualUnreadIds.contains(conversationId) {
                manualUnreadIds.remove(conversationId)
                persist("manualUnread", manualUnreadIds)
            }
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
