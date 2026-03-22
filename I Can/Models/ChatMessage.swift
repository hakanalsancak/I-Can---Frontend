import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }

    var isUser: Bool { role == "user" }
}

struct ChatRequest: Encodable {
    let message: String
    let history: [ChatHistoryItem]
}

struct ChatHistoryItem: Encodable {
    let role: String
    let content: String
}

struct ChatResponse: Decodable {
    let reply: String
    let remaining: Int?
}
