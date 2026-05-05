import Foundation

struct CommunityPost: Identifiable, Codable, Hashable {
    let id: String
    let authorId: String
    let authorUsername: String?
    let authorFullName: String?
    let authorPhotoUrl: String?
    let authorSport: String?
    let type: String
    let visibility: String
    let body: String?
    let photoUrl: String?
    let sport: String?
    let metadata: PostMetadata
    let likeCount: Int
    let commentCount: Int
    let likedByMe: Bool
    let savedByMe: Bool
    let createdAt: String

    var displayName: String {
        if let name = authorFullName, !name.isEmpty { return name }
        if let username = authorUsername, !username.isEmpty { return username }
        return "Athlete"
    }

    var createdAtDate: Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFractional.date(from: createdAt) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: createdAt)
    }
}

struct PostMetadata: Codable, Hashable {
    let raw: [String: AnyCodableValue]

    init(_ raw: [String: AnyCodableValue] = [:]) {
        self.raw = raw
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.raw = [:]
        } else {
            self.raw = (try? container.decode([String: AnyCodableValue].self)) ?? [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

enum AnyCodableValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(Int.self) { self = .int(v); return }
        if let v = try? c.decode(Double.self) { self = .double(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }
}

struct CommunityFeedPage: Codable {
    let items: [CommunityPost]
    let nextCursor: String?
}

struct CreatePostRequest: Encodable {
    let type: String
    let visibility: String
    let body: String?
    let photoUrl: String?
    let sport: String?
}
