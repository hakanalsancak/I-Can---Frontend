import Foundation

struct PostComment: Identifiable, Codable, Hashable {
    let id: String
    let postId: String
    let authorId: String
    let authorUsername: String?
    let authorFullName: String?
    let authorPhotoUrl: String?
    let body: String
    let parentId: String?
    let createdAt: String

    var displayName: String {
        if let n = authorFullName, !n.isEmpty { return n }
        if let u = authorUsername, !u.isEmpty { return u }
        return "Athlete"
    }

    var createdAtDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime]
        return p.date(from: createdAt)
    }
}

struct PostCommentsPage: Codable {
    let items: [PostComment]
    let nextCursor: String?
}
