import Foundation

struct ChatResult {
    let reply: String
    let remaining: Int? // nil = unlimited (premium)
    let conversationId: String?
}

@MainActor
@Observable
final class ChatService {
    static let shared = ChatService()

    /// Resets to `false` on every fresh process launch.
    /// CoachChatView checks this to decide whether to start a blank chat.
    static var hasOpenedChatThisSession = false

    private static let fileName = "coach_chat_history.json"

    func send(message: String, history: [ChatMessage], conversationId: String? = nil) async throws -> ChatResult {
        // Only send last 10 messages to match backend limit and reduce payload size
        let recentHistory = history.suffix(10)
        let historyItems = recentHistory.map { ChatHistoryItem(role: $0.role, content: String($0.content.prefix(2000))) }
        let request = ChatRequest(message: String(message.prefix(2000)), history: historyItems, conversationId: conversationId)
        let response: ChatResponse = try await APIClient.shared.request(
            APIEndpoints.Chat.base,
            method: "POST",
            body: request
        )
        return ChatResult(reply: response.reply, remaining: response.remaining, conversationId: response.conversationId)
    }

    // MARK: - Conversation History

    func fetchConversations(limit: Int = 20, offset: Int = 0) async throws -> ConversationsResponse {
        let endpoint = "\(APIEndpoints.Chat.conversations)?limit=\(limit)&offset=\(offset)"
        return try await APIClient.shared.request(endpoint)
    }

    func fetchMessages(conversationId: String, limit: Int = 50, before: Date? = nil) async throws -> MessagesResponse {
        var endpoint = "\(APIEndpoints.Chat.conversationMessages(conversationId))?limit=\(limit)"
        if let before {
            let formatter = ISO8601DateFormatter()
            endpoint += "&before=\(formatter.string(from: before))"
        }
        return try await APIClient.shared.request(endpoint)
    }

    func renameConversation(_ id: String, title: String) async throws {
        let body = ["title": title]
        let _: [String: Bool] = try await APIClient.shared.request(
            APIEndpoints.Chat.renameConversation(id),
            method: "PATCH",
            body: body
        )
    }

    func togglePin(_ id: String) async throws -> Bool {
        let response: TogglePinResponse = try await APIClient.shared.request(
            APIEndpoints.Chat.togglePin(id),
            method: "PATCH"
        )
        return response.isPinned
    }

    func deleteConversation(_ id: String) async throws {
        let _: [String: Bool] = try await APIClient.shared.request(
            APIEndpoints.Chat.deleteConversation(id),
            method: "DELETE"
        )
    }

    // MARK: - Local Persistence

    func saveMessages(_ messages: [ChatMessage]) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            #if DEBUG
            print("ChatService: failed to save messages - \(error.localizedDescription)")
            #endif
        }
    }

    func loadMessages() -> [ChatMessage] {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ChatMessage].self, from: data)
        } catch {
            #if DEBUG
            print("ChatService: failed to load messages - \(error.localizedDescription)")
            #endif
            return []
        }
    }

    func clearMessages() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
        KeychainHelper.delete(forKey: "chat_limit_reset_at")
    }

    private var fileURL: URL? {
        guard let userId = AuthService.shared.currentUser?.id else {
            // No authenticated user — refuse to read/write chat data
            return nil
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("coach_chat_\(userId).json")
    }

    private init() {}
}
