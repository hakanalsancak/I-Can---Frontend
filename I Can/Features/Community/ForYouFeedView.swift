import SwiftUI

struct ForYouFeedView: View {
    @State private var service = CommunityService.shared
    @State private var sportFeed = SportFeedService.shared
    @State private var showCompose = false
    @State private var loadFailed = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            content
            composeButton
        }
        .task { await initialLoad() }
        .sheet(isPresented: $showCompose) {
            ComposePostView { _ in
                showCompose = false
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if visiblePosts.isEmpty && service.isLoading {
            loadingState
        } else if visiblePosts.isEmpty && loadFailed {
            errorState
        } else if visiblePosts.isEmpty {
            emptyState
        } else {
            feedList
        }
    }

    private func articleAt(injectionIndex: Int) -> SportArticle? {
        let articles = sportFeed.articles
        guard !articles.isEmpty else { return nil }
        return articles[injectionIndex % articles.count]
    }

    private var visiblePosts: [CommunityPost] {
        let mod = ModerationService.shared
        return service.forYouPosts.filter {
            !mod.hiddenPostIds.contains($0.id)
            && !mod.blockedUserIds.contains($0.authorId)
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !service.featuredPosts.isEmpty {
                    featuredRail
                }
                ForEach(Array(visiblePosts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(post: post)
                        .padding(.horizontal, 16)
                        .task {
                            await service.loadMoreIfNeeded(currentItem: post)
                        }
                    if (index + 1) % 3 == 0,
                       let article = articleAt(injectionIndex: index / 3) {
                        NavigationLink {
                            ArticleReaderView(article: article)
                        } label: {
                            InlineArticleRow(article: article)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // When posts are sparse, fill the rest of the feed with sport articles
                if visiblePosts.count < 6 && !sportFeed.articles.isEmpty {
                    HStack {
                        Text("FROM AROUND THE GAME")
                            .font(.system(size: 11, weight: .bold).width(.condensed))
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ForEach(sportFeed.articles.prefix(8)) { article in
                        NavigationLink {
                            ArticleReaderView(article: article)
                        } label: {
                            InlineArticleRow(article: article)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if service.isLoading && !service.forYouPosts.isEmpty {
                    ProgressView()
                        .padding(.vertical, 20)
                }
                Color.clear.frame(height: 80)
            }
            .padding(.top, 12)
        }
        .refreshable { await refresh() }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                PostCardSkeleton()
                    .padding(.horizontal, 16)
            }
            Spacer()
        }
        .padding(.top, 12)
    }

    private var emptyState: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !service.featuredPosts.isEmpty {
                    featuredRail
                }

                VStack(spacing: 6) {
                    Text("Quiet morning.")
                        .font(.system(size: 18, weight: .semibold).width(.condensed))
                    Text("Log a session and it'll show up here.")
                        .font(.system(size: 13).width(.condensed))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

                if !sportFeed.articles.isEmpty {
                    HStack {
                        Text("FROM AROUND THE GAME")
                            .font(.system(size: 11, weight: .bold).width(.condensed))
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ForEach(sportFeed.articles.prefix(8)) { article in
                        NavigationLink {
                            ArticleReaderView(article: article)
                        } label: {
                            InlineArticleRow(article: article)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Color.clear.frame(height: 80)
            }
            .padding(.top, 12)
        }
        .refreshable { await refresh() }
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Couldn't load the feed.")
                .font(.system(size: 16, weight: .semibold).width(.condensed))
            if let msg = errorMessage {
                Text(msg)
                    .font(.system(size: 13).width(.condensed))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button("Retry") {
                Task { await refresh() }
            }
            .buttonStyle(.borderedProminent)
            .tint(ColorTheme.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var composeButton: some View {
        Button {
            showCompose = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(ColorTheme.accent, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func initialLoad() async {
        async let featured: () = service.loadFeatured()
        async let articles: ()? = sportFeed.articles.isEmpty
            ? (try? await sportFeed.load(refresh: true))
            : nil
        _ = await featured
        _ = await articles
        guard service.forYouPosts.isEmpty else { return }
        await refresh()
    }

    private func refresh() async {
        async let featured: () = service.loadFeatured()
        async let articles: ()? = (try? await sportFeed.load(refresh: true))
        do {
            try await service.loadForYou(refresh: true)
            loadFailed = false
            errorMessage = nil
        } catch {
            loadFailed = true
            errorMessage = (error as? APIError)?.userMessage ?? "Try again in a moment."
        }
        _ = await featured
        _ = await articles
    }

    private var featuredRail: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FEATURED")
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .tracking(0.6)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(service.featuredPosts) { post in
                        FeaturedCardView(post: post)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

private struct FeaturedCardView: View {
    let post: CommunityPost
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationLink {
            PostDetailView(postId: post.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 11, weight: .semibold).width(.condensed))
                                .foregroundStyle(ColorTheme.accent)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.displayName)
                            .font(.system(size: 12, weight: .semibold).width(.condensed))
                            .lineLimit(1)
                        if let s = post.authorSport {
                            Text(s.capitalized)
                                .font(.system(size: 10).width(.condensed))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                if let body = post.body {
                    Text(body)
                        .font(.system(size: 13).width(.condensed))
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                HStack(spacing: 12) {
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                    Spacer()
                }
                .font(.system(size: 11).width(.condensed).monospacedDigit())
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(height: 150, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.05)
                          : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = post.displayName.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let s = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (f + s).uppercased()
    }
}

private struct PostCardSkeleton: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle().frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 10)
                    RoundedRectangle(cornerRadius: 4).frame(width: 80, height: 8)
                }
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4).frame(height: 12)
            RoundedRectangle(cornerRadius: 4).frame(width: 240, height: 12)
        }
        .foregroundStyle(.secondary.opacity(pulse ? 0.15 : 0.3))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct InlineArticleRow: View {
    let article: SportArticle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumb
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(article.categoryLabel)
                    .font(.system(size: 9, weight: .bold).width(.condensed))
                    .tracking(0.5)
                    .foregroundStyle(ColorTheme.accent)
                Text(article.title)
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(article.sourceName)
                    .font(.system(size: 11).width(.condensed))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var thumb: some View {
        if let s = article.imageUrl, let url = URL(string: s) {
            Color.clear.overlay(
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        ColorTheme.accent.opacity(0.15)
                    }
                }
            )
        } else {
            ColorTheme.accent.opacity(0.15)
                .overlay(
                    Image(systemName: "newspaper.fill")
                        .foregroundStyle(ColorTheme.accent.opacity(0.6))
                )
        }
    }
}

private extension APIError {
    var userMessage: String {
        switch self {
        case .networkError: return "No internet."
        case .serverError(let msg): return msg
        case .unauthorized: return "Please sign in again."
        default: return "Try again in a moment."
        }
    }
}
