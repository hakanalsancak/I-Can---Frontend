import SwiftUI

struct SportFeedView: View {
    @State private var service = SportFeedService.shared
    @State private var loadFailed = false
    @State private var errorMessage: String?
    @State private var selectedFilter: String = "all"
    @Environment(\.colorScheme) private var colorScheme

    private let filters: [(id: String, label: String, value: String?)] = [
        ("all", "All", nil),
        ("training", "Training", "training"),
        ("recovery", "Recovery", "recovery"),
        ("mindset", "Mindset", "mindset"),
        ("news", "News", "news"),
    ]

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            VStack(spacing: 0) {
                filterBar
                Divider().opacity(0.3)
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await initialLoad() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.id) { f in
                    Button {
                        Task { await applyFilter(f.value) }
                    } label: {
                        Text(f.label)
                            .font(.system(size: 13, weight: selectedFilter == f.id ? .semibold : .regular).width(.condensed))
                            .foregroundStyle(selectedFilter == f.id ? Color.white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(selectedFilter == f.id
                                               ? AnyShapeStyle(ColorTheme.accent)
                                               : AnyShapeStyle(Color.secondary.opacity(0.12)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var content: some View {
        if service.articles.isEmpty && service.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if service.articles.isEmpty && loadFailed {
            errorState
        } else if service.articles.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(service.articles) { article in
                    NavigationLink {
                        ArticleReaderView(article: article)
                    } label: {
                        ArticleCardView(article: article)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .task { await service.loadMoreIfNeeded(currentItem: article) }
                }
                if service.isLoading && !service.articles.isEmpty {
                    ProgressView().padding(.vertical, 20)
                }
                Color.clear.frame(height: 60)
            }
            .padding(.top, 12)
        }
        .refreshable { await refresh() }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Pulling fresh content.")
                .font(.system(size: 16, weight: .semibold).width(.condensed))
            Text("Check back in a minute.")
                .font(.system(size: 13).width(.condensed))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Couldn't load articles.")
                .font(.system(size: 16, weight: .semibold).width(.condensed))
            if let m = errorMessage {
                Text(m).font(.system(size: 13).width(.condensed)).foregroundStyle(.secondary)
            }
            Button("Retry") { Task { await refresh() } }
                .buttonStyle(.borderedProminent)
                .tint(ColorTheme.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func initialLoad() async {
        guard service.articles.isEmpty else { return }
        await refresh()
    }

    private func applyFilter(_ value: String?) async {
        selectedFilter = value ?? "all"
        service.category = value
        await refresh()
    }

    private func refresh() async {
        do {
            try await service.load(refresh: true)
            loadFailed = false
            errorMessage = nil
        } catch {
            loadFailed = true
            errorMessage = (error as? APIError)?.errorDescription ?? "Try again."
        }
    }
}

private struct ArticleCardView: View {
    let article: SportArticle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroImage

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    categoryBadge
                    Text(relativeTime)
                        .font(.system(size: 11).width(.condensed))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text(article.title)
                    .font(.system(size: 17, weight: .semibold).width(.condensed))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !article.bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(article.bullets.prefix(3), id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(bullet)
                                    .font(.system(size: 13).width(.condensed))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    Text(article.sourceName.uppercased())
                        .font(.system(size: 10, weight: .semibold).width(.condensed))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var categoryBadge: some View {
        Text(article.categoryLabel)
            .font(.system(size: 10, weight: .bold).width(.condensed))
            .tracking(0.6)
            .foregroundStyle(ColorTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(ColorTheme.accent.opacity(0.12))
            )
    }

    @ViewBuilder
    private var heroImage: some View {
        if let urlString = article.imageUrl, let url = URL(string: urlString) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .overlay(
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty, .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                )
                .clipped()
        }
    }

    private var placeholder: some View {
        ZStack {
            ColorTheme.accent.opacity(0.15)
            Image(systemName: "newspaper.fill")
                .font(.system(size: 32))
                .foregroundStyle(ColorTheme.accent.opacity(0.6))
        }
    }

    private var relativeTime: String {
        guard let d = article.publishedDate else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }
}
