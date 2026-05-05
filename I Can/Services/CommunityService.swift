import Foundation

@MainActor
@Observable
final class CommunityService {
    static let shared = CommunityService()

    private(set) var forYouPosts: [CommunityPost] = []
    private(set) var isLoading = false
    private(set) var nextCursor: String?
    private(set) var hasReachedEnd = false

    private(set) var friendsPosts: [CommunityPost] = []
    private(set) var friendsLoading = false
    private(set) var friendsNextCursor: String?
    private(set) var friendsHasReachedEnd = false

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

    func loadFriendsFeed(refresh: Bool = false) async throws {
        if friendsLoading { return }
        if refresh {
            friendsNextCursor = nil
            friendsHasReachedEnd = false
        }
        friendsLoading = true
        defer { friendsLoading = false }

        var endpoint = APIEndpoints.Community.friendsFeed + "?limit=20"
        if let cursor = friendsNextCursor,
           let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&cursor=\(encoded)"
        }

        let page: CommunityFeedPage = try await APIClient.shared.request(endpoint)
        if refresh || friendsNextCursor == nil {
            friendsPosts = page.items
        } else {
            let existing = Set(friendsPosts.map(\.id))
            friendsPosts.append(contentsOf: page.items.filter { !existing.contains($0.id) })
        }
        friendsNextCursor = page.nextCursor
        friendsHasReachedEnd = page.nextCursor == nil
    }

    func loadMoreFriendsIfNeeded(currentItem: CommunityPost) async {
        guard !friendsHasReachedEnd, !friendsLoading else { return }
        guard let idx = friendsPosts.firstIndex(of: currentItem) else { return }
        if idx >= friendsPosts.count - 5 {
            try? await loadFriendsFeed(refresh: false)
        }
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

    @discardableResult
    func toggleLike(postId: String) async throws -> Bool {
        guard let original = currentPost(postId) else { return false }
        let willLike = !original.likedByMe
        let newCount = max(original.likeCount + (willLike ? 1 : -1), 0)
        applyMutation(postId) { p in
            mutated(p, likedByMe: willLike, likeCount: newCount)
        }

        struct Resp: Decodable { let liked: Bool; let likeCount: Int }
        do {
            let r: Resp = try await APIClient.shared.request(
                APIEndpoints.Community.like(postId),
                method: willLike ? "POST" : "DELETE"
            )
            applyMutation(postId) { p in
                mutated(p, likedByMe: r.liked, likeCount: r.likeCount)
            }
            return r.liked
        } catch {
            applyMutation(postId) { p in
                mutated(p, likedByMe: original.likedByMe, likeCount: original.likeCount)
            }
            throw error
        }
    }

    @discardableResult
    func toggleSave(postId: String) async throws -> Bool {
        guard let original = currentPost(postId) else { return false }
        let willSave = !original.savedByMe
        applyMutation(postId) { p in mutated(p, savedByMe: willSave) }

        struct Resp: Decodable { let saved: Bool }
        do {
            let r: Resp = try await APIClient.shared.request(
                APIEndpoints.Community.save(postId),
                method: willSave ? "POST" : "DELETE"
            )
            applyMutation(postId) { p in mutated(p, savedByMe: r.saved) }
            return r.saved
        } catch {
            applyMutation(postId) { p in mutated(p, savedByMe: original.savedByMe) }
            throw error
        }
    }

    private func currentPost(_ id: String) -> CommunityPost? {
        forYouPosts.first(where: { $0.id == id })
            ?? friendsPosts.first(where: { $0.id == id })
    }

    private func applyMutation(_ postId: String, _ transform: (CommunityPost) -> CommunityPost) {
        if let i = forYouPosts.firstIndex(where: { $0.id == postId }) {
            forYouPosts[i] = transform(forYouPosts[i])
        }
        if let i = friendsPosts.firstIndex(where: { $0.id == postId }) {
            friendsPosts[i] = transform(friendsPosts[i])
        }
    }

    func loadComments(postId: String, cursor: String? = nil, limit: Int = 30) async throws -> PostCommentsPage {
        var endpoint = APIEndpoints.Community.comments(postId) + "?limit=\(limit)"
        if let cursor, let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&cursor=\(encoded)"
        }
        let page: PostCommentsPage = try await APIClient.shared.request(endpoint)
        return page
    }

    func createComment(postId: String, body: String, parentId: String? = nil) async throws -> PostComment {
        struct Body: Encodable { let body: String; let parentId: String? }
        let comment: PostComment = try await APIClient.shared.request(
            APIEndpoints.Community.comments(postId),
            method: "POST",
            body: Body(body: body, parentId: parentId)
        )
        applyMutation(postId) { p in mutated(p, commentCount: p.commentCount + 1) }
        return comment
    }

    func deleteComment(id: String, postId: String) async throws {
        struct Resp: Decodable { let id: String; let deleted: Bool }
        let _: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.deleteComment(id),
            method: "DELETE"
        )
        applyMutation(postId) { p in mutated(p, commentCount: max(p.commentCount - 1, 0)) }
    }

    private func mutated(_ p: CommunityPost,
                          likedByMe: Bool? = nil,
                          savedByMe: Bool? = nil,
                          likeCount: Int? = nil,
                          commentCount: Int? = nil) -> CommunityPost {
        CommunityPost(
            id: p.id,
            authorId: p.authorId,
            authorUsername: p.authorUsername,
            authorFullName: p.authorFullName,
            authorPhotoUrl: p.authorPhotoUrl,
            authorSport: p.authorSport,
            type: p.type,
            visibility: p.visibility,
            body: p.body,
            photoUrl: p.photoUrl,
            sport: p.sport,
            metadata: p.metadata,
            likeCount: likeCount ?? p.likeCount,
            commentCount: commentCount ?? p.commentCount,
            likedByMe: likedByMe ?? p.likedByMe,
            savedByMe: savedByMe ?? p.savedByMe,
            createdAt: p.createdAt
        )
    }
}
