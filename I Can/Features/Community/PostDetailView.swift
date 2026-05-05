import SwiftUI

struct PostDetailView: View {
    let postId: String

    @State private var service = CommunityService.shared
    @State private var post: CommunityPost?
    @State private var comments: [PostComment] = []
    @State private var nextCursor: String?
    @State private var hasReachedEnd = false
    @State private var isLoadingPost = true
    @State private var isLoadingComments = false
    @State private var draft: String = ""
    @State private var isSubmitting = false
    @State private var error: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if let post {
                        PostCardView(post: post)
                            .padding(.horizontal, 16)
                    } else if isLoadingPost {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    }

                    if !comments.isEmpty {
                        Text("Comments")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    ForEach(comments) { comment in
                        commentRow(comment)
                            .padding(.horizontal, 16)
                            .task { await loadMoreIfNeeded(currentItem: comment) }
                    }

                    if isLoadingComments && !comments.isEmpty {
                        ProgressView().padding(.vertical, 12)
                    }

                    Color.clear.frame(height: 12)
                }
                .padding(.top, 12)
            }

            commentBox
        }
        .background(ColorTheme.background(colorScheme).ignoresSafeArea())
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await initialLoad() }
    }

    private func commentRow(_ c: PostComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            avatar(for: c)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(c.displayName)
                        .font(.system(size: 13, weight: .semibold))
                    Text(relative(c.createdAtDate))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Text(c.body)
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func avatar(for c: PostComment) -> some View {
        if let s = c.authorPhotoUrl, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
        } else {
            Circle().fill(ColorTheme.accent.opacity(0.18))
                .overlay(
                    Text(initials(c.displayName))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ColorTheme.accent)
                )
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let s = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (f + s).uppercased()
    }

    private func relative(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }

    private var commentBox: some View {
        VStack(spacing: 0) {
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
            HStack(spacing: 8) {
                TextField("Add something useful…", text: $draft, axis: .vertical)
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
                Button {
                    Task { await submit() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(canSubmit ? ColorTheme.accent : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }

    private var canSubmit: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 1000 && !isSubmitting
    }

    private func initialLoad() async {
        isLoadingPost = true
        do {
            let p: CommunityPost = try await APIClient.shared.request(
                APIEndpoints.Community.post(postId)
            )
            post = p
        } catch {
            self.error = "Couldn't load post."
        }
        isLoadingPost = false
        await loadComments(refresh: true)
    }

    private func loadComments(refresh: Bool) async {
        if isLoadingComments { return }
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            let cursor = refresh ? nil : nextCursor
            let page = try await service.loadComments(postId: postId, cursor: cursor)
            if refresh {
                comments = page.items
            } else {
                let existing = Set(comments.map(\.id))
                comments.append(contentsOf: page.items.filter { !existing.contains($0.id) })
            }
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
        } catch {
            // silent for pagination
        }
    }

    private func loadMoreIfNeeded(currentItem: PostComment) async {
        guard !hasReachedEnd, !isLoadingComments else { return }
        guard let idx = comments.firstIndex(of: currentItem) else { return }
        if idx >= comments.count - 5 {
            await loadComments(refresh: false)
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let new = try await service.createComment(postId: postId, body: trimmed)
            comments.insert(new, at: 0)
            draft = ""
            error = nil
            // reflect updated count on local post
            if var p = post {
                p = CommunityPost(
                    id: p.id, authorId: p.authorId,
                    authorUsername: p.authorUsername, authorFullName: p.authorFullName,
                    authorPhotoUrl: p.authorPhotoUrl, authorSport: p.authorSport,
                    type: p.type, visibility: p.visibility,
                    body: p.body, photoUrl: p.photoUrl,
                    sport: p.sport, metadata: p.metadata,
                    likeCount: p.likeCount, commentCount: p.commentCount + 1,
                    likedByMe: p.likedByMe, savedByMe: p.savedByMe,
                    createdAt: p.createdAt
                )
                post = p
            }
        } catch {
            self.error = (error as? APIError)?.errorDescription ?? "Couldn't post comment."
        }
    }
}
