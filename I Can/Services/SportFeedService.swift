import Foundation

@MainActor
@Observable
final class SportFeedService {
    static let shared = SportFeedService()

    private(set) var articles: [SportArticle] = []
    private(set) var isLoading = false
    private(set) var nextCursor: String?
    private(set) var hasReachedEnd = false
    var category: String?

    private init() {}

    func load(refresh: Bool = false) async throws {
        if isLoading { return }
        if refresh {
            nextCursor = nil
            hasReachedEnd = false
        }
        isLoading = true
        defer { isLoading = false }

        var endpoint = APIEndpoints.Community.sportFeed + "?limit=20"
        if let cursor = nextCursor,
           let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&cursor=\(encoded)"
        }
        if let c = category {
            endpoint += "&category=\(c)"
        }

        let page: SportArticlesPage = try await APIClient.shared.request(endpoint)
        if refresh || nextCursor == nil {
            articles = page.items
        } else {
            let existing = Set(articles.map(\.id))
            articles.append(contentsOf: page.items.filter { !existing.contains($0.id) })
        }
        nextCursor = page.nextCursor
        hasReachedEnd = page.nextCursor == nil
    }

    func loadMoreIfNeeded(currentItem: SportArticle) async {
        guard !hasReachedEnd, !isLoading else { return }
        guard let idx = articles.firstIndex(of: currentItem) else { return }
        if idx >= articles.count - 5 {
            try? await load(refresh: false)
        }
    }

    func track(article: SportArticle, action: String) async {
        struct Body: Encodable { let articleId: String; let action: String }
        struct Resp: Decodable { let ok: Bool }
        do {
            let _: Resp = try await APIClient.shared.request(
                APIEndpoints.Community.trackArticle,
                method: "POST",
                body: Body(articleId: article.id, action: action)
            )
        } catch {
            // best-effort tracking, ignore failures
        }
    }
}
