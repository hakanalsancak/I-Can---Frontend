import Foundation

/// Shared ISO8601 parsing with memoization. Naive `ISO8601DateFormatter()`
/// allocations in property getters were the single largest source of chat-typing
/// lag — a 100-message conversation would allocate 100s of formatters per
/// keystroke during render-time sorts.
enum DMDate {
    private static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let cacheLock = NSLock()
    private static var cache: [String: Date] = [:]
    private static let cacheLimit = 4096

    static func parse(_ string: String) -> Date? {
        cacheLock.lock()
        if let hit = cache[string] {
            cacheLock.unlock()
            return hit
        }
        cacheLock.unlock()

        let parsed = withFractional.date(from: string) ?? plain.date(from: string)

        if let parsed {
            cacheLock.lock()
            if cache.count >= cacheLimit { cache.removeAll(keepingCapacity: true) }
            cache[string] = parsed
            cacheLock.unlock()
        }
        return parsed
    }

    static func now() -> String {
        withFractional.string(from: Date())
    }
}

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
        return DMDate.parse(s)
    }
}

struct DMConversationsPage: Codable {
    let items: [DMConversation]
}

struct DMAttachmentRef: Codable, Hashable {
    let url: String
    let durationMs: Int?
    let width: Int?
    let height: Int?
}

struct DMMessage: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let body: String?
    let attachmentType: String?
    let attachmentRef: DMAttachmentRef?
    let createdAt: String

    var createdAtDate: Date? {
        DMDate.parse(createdAt)
    }
}

struct DMMessagesPage: Codable {
    let items: [DMMessage]
    let nextCursor: String?
}
