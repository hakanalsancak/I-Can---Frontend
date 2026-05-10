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
    /// Per-conversation hide timestamp. A chat stays hidden only while its
    /// `lastMessageDate` is `<=` this date — any newer activity (incoming or
    /// outgoing) lifts the hide automatically, mirroring WhatsApp.
    private(set) var hiddenAt: [String: Date] = [:]
    private(set) var manualUnreadIds: Set<String> = []

    private var loadedLocalUserId: String?

    private init() {}

    var totalUnread: Int {
        var total = 0
        for c in conversations {
            if isHidden(c) { continue }
            if archivedIds.contains(c.id) { continue }
            if mutedIds.contains(c.id) { continue }
            let count = manualUnreadIds.contains(c.id) ? max(c.unreadCount, 1) : c.unreadCount
            total += count
        }
        return total
    }

    var visibleConversations: [DMConversation] {
        conversations.filter { !isHidden($0) }
    }

    /// A conversation is hidden iff it carries a hide stamp AND no newer
    /// message has arrived since. Missing `lastMessageDate` is treated as
    /// "no new activity," so the hide stays in effect.
    private func isHidden(_ c: DMConversation) -> Bool {
        guard let hideDate = hiddenAt[c.id] else { return false }
        guard let last = c.lastMessageDate else { return true }
        return last <= hideDate
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
        unhideStaleEntries()
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
        hiddenAt = readHiddenAt(d)
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
    /// Backend keeps the thread; the hide is lifted automatically the next
    /// time a message newer than this stamp arrives, or when the user
    /// actively re-engages with this chat.
    func hideConversation(_ id: String) {
        hiddenAt[id] = Date()
        pinnedIds.remove(id)
        archivedIds.remove(id)
        manualUnreadIds.remove(id)
        persist("pinned", pinnedIds)
        persist("archived", archivedIds)
        persist("manualUnread", manualUnreadIds)
        persistHiddenAt()
        conversations.removeAll { $0.id == id }
    }

    /// Drops the hide stamp for `id` and, if the conversation is no longer
    /// in the in-memory cache (because `hideConversation` removed it),
    /// kicks off a background refresh so the inbox repopulates it.
    private func evictHidden(_ id: String) {
        guard hiddenAt.removeValue(forKey: id) != nil else { return }
        persistHiddenAt()
        if !conversations.contains(where: { $0.id == id }) {
            Task { try? await loadInbox() }
        }
    }

    /// Drops persisted ids that no longer exist server-side. `hiddenAt` is
    /// pruned by `unhideStaleEntries` instead — its sticky-with-resurrection
    /// semantics differ from the other sets.
    private func prunePersistedState() {
        let live = Set(conversations.map { $0.id })
        prune(&pinnedIds, live: live, name: "pinned")
        prune(&mutedIds, live: live, name: "muted")
        prune(&archivedIds, live: live, name: "archived")
        prune(&manualUnreadIds, live: live, name: "manualUnread")
    }

    /// Lifts the hide stamp on any conversation whose latest message is
    /// newer than the stamp — i.e. a friend wrote back, or we sent
    /// something. This is the "new messages will bring the chat back" path.
    private func unhideStaleEntries() {
        guard !hiddenAt.isEmpty else { return }
        var changed = false
        for c in conversations {
            if let hideDate = hiddenAt[c.id],
               let last = c.lastMessageDate,
               last > hideDate {
                hiddenAt.removeValue(forKey: c.id)
                changed = true
            }
        }
        if changed { persistHiddenAt() }
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

    /// Reads the hide-stamp dictionary. Falls back to the legacy `hidden`
    /// `[String]` format from earlier builds and migrates it forward by
    /// stamping every entry with "now," so previously-hidden chats stay
    /// hidden until a newer message arrives — same as freshly hiding them.
    private func readHiddenAt(_ d: UserDefaults) -> [String: Date] {
        let key = storageKey("hiddenAt")
        if let raw = d.dictionary(forKey: key) as? [String: Double] {
            return raw.mapValues { Date(timeIntervalSince1970: $0) }
        }
        let legacyKey = storageKey("hidden")
        if let arr = d.array(forKey: legacyKey) as? [String], !arr.isEmpty {
            let now = Date()
            return Dictionary(uniqueKeysWithValues: arr.map { ($0, now) })
        }
        return [:]
    }

    private func persistHiddenAt() {
        let raw: [String: Double] = hiddenAt.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(raw, forKey: storageKey("hiddenAt"))
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
        // Re-engaging with a previously-hidden chat lifts the hide so it
        // resurfaces in the inbox once we (or they) send the next message.
        evictHidden(r.id)
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
        evictHidden(conversationId)
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
        evictHidden(conversationId)
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
