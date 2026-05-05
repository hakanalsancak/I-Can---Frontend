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

    func sendAttachment(
        conversationId: String,
        kind: String,
        attachment: DMAttachmentRef,
        body: String? = nil
    ) async throws -> DMMessage {
        struct Body: Encodable {
            let body: String?
            let attachmentType: String
            let attachmentRef: DMAttachmentRef
        }
        let m: DMMessage = try await APIClient.shared.request(
            APIEndpoints.Community.sendMessage(conversationId),
            method: "POST",
            body: Body(body: body, attachmentType: kind, attachmentRef: attachment)
        )
        return m
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
