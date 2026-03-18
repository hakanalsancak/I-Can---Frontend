import Foundation

@MainActor
@Observable
final class ChatService {
    static let shared = ChatService()

    func send(message: String, history: [ChatMessage]) async throws -> String {
        let historyItems = history.map { ChatHistoryItem(role: $0.role, content: $0.content) }
        let request = ChatRequest(message: message, history: historyItems)
        let response: ChatResponse = try await APIClient.shared.request(
            APIEndpoints.Chat.base,
            method: "POST",
            body: request
        )
        return response.reply
    }

    private init() {}
}
