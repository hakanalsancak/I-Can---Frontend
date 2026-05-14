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
    let lastSeenAt: String?

    var displayName: String {
        if let n = fullName, !n.isEmpty { return n }
        if let u = username, !u.isEmpty { return u }
        return "Athlete"
    }
}

/// Treats a user as online if they made an authenticated request within the
/// last `windowSeconds`. Matches the 30s presence-write debounce on the
/// server with a generous buffer to avoid flapping while polls are in flight.
enum DMPresence {
    static let onlineWindow: TimeInterval = 90

    static func isOnline(_ lastSeenAt: String?) -> Bool {
        guard let s = lastSeenAt, let d = DMDate.parse(s) else { return false }
        return Date().timeIntervalSince(d) < onlineWindow
    }

    /// "Last seen 4 minutes ago" / "Last seen yesterday at 21:14" / etc.
    /// Returns nil if no timestamp is available.
    static func lastSeenDescription(_ lastSeenAt: String?) -> String? {
        guard let s = lastSeenAt, let d = DMDate.parse(s) else { return nil }
        let elapsed = Date().timeIntervalSince(d)
        if elapsed < 60 { return "Last seen just now" }
        let minutes = Int(elapsed / 60)
        if minutes < 60 { return "Last seen \(minutes) min ago" }
        let hours = minutes / 60
        if hours < 24 { return "Last seen \(hours) hr ago" }
        let cal = Calendar.current
        if cal.isDateInYesterday(d) {
            return "Last seen yesterday at \(timeFormatter.string(from: d))"
        }
        let days = cal.dateComponents([.day], from: d, to: Date()).day ?? 0
        if days < 7 { return "Last seen \(days) days ago" }
        return "Last seen \(dateFormatter.string(from: d))"
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: .current) ?? "HH:mm"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM d", options: 0, locale: .current) ?? "MMM d"
        return f
    }()
}

struct DMConversationLastMessage: Codable, Hashable {
    let senderId: String
    let body: String
    let createdAt: String
    let isSystem: Bool?
}

enum DMGroupRole: String, Codable, Hashable {
    case admin
    case member
}

struct DMConversation: Identifiable, Codable, Hashable {
    let id: String
    let isGroup: Bool
    let title: String?
    let photoUrl: String?
    let creatorId: String?
    let viewerRole: DMGroupRole?
    let memberCount: Int?
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

/// Compact snapshot of the message being quoted. Denormalized server-side so
/// we can render the quote box without a second fetch and without breaking
/// when the original is later deleted.
struct DMReplyPreview: Codable, Hashable {
    let id: String
    let senderId: String
    let body: String?
    let attachmentType: String?
}

struct DMMessage: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let body: String?
    let attachmentType: String?
    let attachmentRef: DMAttachmentRef?
    let createdAt: String
    let deliveredAt: String?
    let readAt: String?
    let isSystem: Bool?
    let systemEvent: String?
    let replyTo: DMReplyPreview?

    var isSystemMessage: Bool { isSystem == true }

    var createdAtDate: Date? {
        DMDate.parse(createdAt)
    }

    /// Read-receipt state for a message I sent. Recipient-side messages always
    /// resolve to `.none` so callers can render nothing.
    enum ReceiptState {
        case none      // not my message, or pending placeholder
        case sending   // optimistic local placeholder, no server id yet
        case sent      // server confirmed, recipient hasn't fetched
        case delivered // recipient pulled the conversation
        case read      // recipient opened the chat after delivery
    }

    func receiptState(currentUserId: String?) -> ReceiptState {
        guard let currentUserId, senderId == currentUserId else { return .none }
        if id.hasPrefix("pending-") { return .sending }
        if readAt != nil { return .read }
        if deliveredAt != nil { return .delivered }
        return .sent
    }
}

struct DMMessagesPage: Codable {
    let items: [DMMessage]
    let nextCursor: String?
    let otherLastSeenAt: String?
}

struct DMGroupMember: Codable, Hashable, Identifiable {
    let id: String
    let role: DMGroupRole
    let joinedAt: String?
    let fullName: String?
    let username: String?
    let photoUrl: String?
    let sport: String?
    let lastSeenAt: String?

    var displayName: String {
        if let n = fullName, !n.isEmpty { return n }
        if let u = username, !u.isEmpty { return u }
        return "Athlete"
    }
}

struct DMGroupInfo: Codable, Hashable {
    let id: String
    let isGroup: Bool
    let title: String?
    let photoUrl: String?
    let creatorId: String?
    let viewerRole: DMGroupRole
    let members: [DMGroupMember]
}
