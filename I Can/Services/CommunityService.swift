import Foundation

@MainActor
@Observable
final class CommunityService {
    static let shared = CommunityService()

    private(set) var forYouPosts: [CommunityPost] = []
    private(set) var isLoading = false
    private(set) var nextCursor: String?
    private(set) var hasReachedEnd = false

    private init() {}

    func loadForYou(refresh: Bool = false) async throws {
        if isLoading { return }
        if refresh {
            nextCursor = nil
            hasReachedEnd = false
        }
        isLoading = true
        defer { isLoading = false }

        var endpoint = APIEndpoints.Community.forYou + "?limit=20"
        if let cursor = nextCursor,
           let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&cursor=\(encoded)"
        }

        let page: CommunityFeedPage = try await APIClient.shared.request(endpoint)

        if refresh || nextCursor == nil {
            forYouPosts = page.items
        } else {
            let existing = Set(forYouPosts.map(\.id))
            let merged = forYouPosts + page.items.filter { !existing.contains($0.id) }
            forYouPosts = merged
        }
        nextCursor = page.nextCursor
        if page.nextCursor == nil { hasReachedEnd = true }
    }

    func loadMoreIfNeeded(currentItem: CommunityPost) async {
        guard !hasReachedEnd, !isLoading else { return }
        guard let idx = forYouPosts.firstIndex(of: currentItem) else { return }
        let threshold = forYouPosts.count - 5
        if idx >= threshold {
            try? await loadForYou(refresh: false)
        }
    }

    func createPost(
        type: String,
        body: String?,
        visibility: String = "public",
        photoUrl: String? = nil,
        sport: String? = nil
    ) async throws -> CommunityPost {
        let request = CreatePostRequest(
            type: type,
            visibility: visibility,
            body: body,
            photoUrl: photoUrl,
            sport: sport
        )
        let post: CommunityPost = try await APIClient.shared.request(
            APIEndpoints.Community.posts,
            method: "POST",
            body: request
        )
        forYouPosts.insert(post, at: 0)
        return post
    }

    func deletePost(id: String) async throws {
        struct DeleteResponse: Decodable { let id: String; let deleted: Bool }
        let _: DeleteResponse = try await APIClient.shared.request(
            APIEndpoints.Community.post(id),
            method: "DELETE"
        )
        forYouPosts.removeAll { $0.id == id }
    }
}
