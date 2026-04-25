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

    init(role: String, content: String, timestamp: Date) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    var isUser: Bool { role == "user" }
}

struct ChatRequest: Encodable {
    let message: String
    let history: [ChatHistoryItem]
    let conversationId: String?
    let clientDate: String
    let clientTimezone: String

    init(message: String, history: [ChatHistoryItem], conversationId: String? = nil) {
        self.message = message
        self.history = history
        self.conversationId = conversationId

        let tz = TimeZone.current
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = tz
        formatter.dateFormat = "yyyy-MM-dd"
        self.clientDate = formatter.string(from: Date())
        self.clientTimezone = tz.identifier
    }
}

struct ChatHistoryItem: Encodable {
    let role: String
    let content: String
}

struct ChatResponse: Decodable {
    let reply: String
    let remaining: Int?
    let conversationId: String?
}

// MARK: - Conversation History Models

struct Conversation: Identifiable, Codable {
    let id: String
    var title: String?
    let lastMessage: String?
    let messageCount: Int
    var isPinned: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, lastMessage, messageCount, isPinned, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        messageCount = try container.decode(Int.self, forKey: .messageCount)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct ConversationsResponse: Decodable {
    let conversations: [Conversation]
    let total: Int
}

struct TogglePinResponse: Decodable {
    let success: Bool
    let isPinned: Bool
}

struct MessagesResponse: Decodable {
    let messages: [ServerChatMessage]
    let hasMore: Bool
}

struct ServerChatMessage: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let createdAt: Date

    var isUser: Bool { role == "user" }

    func toChatMessage() -> ChatMessage {
        ChatMessage(role: role, content: content, timestamp: createdAt)
    }
}
