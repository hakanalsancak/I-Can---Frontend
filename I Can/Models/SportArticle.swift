import Foundation

struct SportArticle: Identifiable, Codable, Hashable {
    let id: String
    let sport: String
    let category: String
    let title: String
    let summary: String
    let sourceName: String
    let sourceUrl: String
    let imageUrl: String?
    let relevanceScore: Int
    let publishedAt: String

    var bullets: [String] {
        summary.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    var publishedDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: publishedAt) { return d }
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime]
        return p.date(from: publishedAt)
    }

    var categoryLabel: String {
        switch category {
        case "training": return "TRAINING"
        case "recovery": return "RECOVERY"
        case "mindset": return "MINDSET"
        case "news": return "NEWS"
        default: return category.uppercased()
        }
    }
}

struct SportArticlesPage: Codable {
    let items: [SportArticle]
    let nextCursor: String?
}
