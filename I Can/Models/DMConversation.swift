import Foundation

struct DMConversationOther: Codable, Hashable {
    let id: String
    let fullName: String?
    let username: String?
    let photoUrl: String?
    let sport: String?

    var displayName: String {
        if let n = fullName, !n.isEmpty { return n }
        if let u = username, !u.isEmpty { return u }
        return "Athlete"
    }
}

struct DMConversationLastMessage: Codable, Hashable {
    let senderId: String
    let body: String
    let createdAt: String
}

struct DMConversation: Identifiable, Codable, Hashable {
    let id: String
    let isGroup: Bool
    let title: String?
    let isRequest: Bool
    let lastMessageAt: String?
    let lastReadAt: String?
    let unreadCount: Int
    let other: DMConversationOther?
    let lastMessage: DMConversationLastMessage?

    var displayName: String {
        if let t = title, !t.isEmpty { return t }
        return other?.displayName ?? "Chat"
    }

    var lastMessageDate: Date? {
        guard let s = lastMessageAt else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime]
        return p.date(from: s)
    }
}

struct DMConversationsPage: Codable {
    let items: [DMConversation]
}

struct DMMessage: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let body: String?
    let attachmentType: String?
    let createdAt: String

    var createdAtDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime]
        return p.date(from: createdAt)
    }
}

struct DMMessagesPage: Codable {
    let items: [DMMessage]
    let nextCursor: String?
}
