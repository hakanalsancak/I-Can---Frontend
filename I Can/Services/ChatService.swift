import Foundation

struct ChatResult {
    let reply: String
    let remaining: Int? // nil = unlimited (premium)
}

@MainActor
@Observable
final class ChatService {
    static let shared = ChatService()

    private static let fileName = "coach_chat_history.json"

    func send(message: String, history: [ChatMessage]) async throws -> ChatResult {
        let historyItems = history.map { ChatHistoryItem(role: $0.role, content: $0.content) }
        let request = ChatRequest(message: message, history: historyItems)
        let response: ChatResponse = try await APIClient.shared.request(
            APIEndpoints.Chat.base,
            method: "POST",
            body: request
        )
        return ChatResult(reply: response.reply, remaining: response.remaining)
    }

    func saveMessages(_ messages: [ChatMessage]) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: url, options: .atomic)
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
        UserDefaults.standard.removeObject(forKey: "chat_limit_reset_at")
    }

    private var fileURL: URL? {
        guard let userId = AuthService.shared.currentUser?.id else {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(Self.fileName)
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("coach_chat_\(userId).json")
    }

    private init() {}
}
