import SwiftUI

struct ForYouFeedView: View {
    @State private var service = CommunityService.shared
    @State private var showCompose = false
    @State private var loadFailed = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
        if service.forYouPosts.isEmpty && service.isLoading {
            loadingState
        } else if service.forYouPosts.isEmpty && loadFailed {
            errorState
        } else if service.forYouPosts.isEmpty {
            emptyState
        } else {
            feedList
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(service.forYouPosts) { post in
                    PostCardView(post: post)
                        .padding(.horizontal, 16)
                        .task {
                            await service.loadMoreIfNeeded(currentItem: post)
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
        VStack(spacing: 8) {
            Spacer()
            Text("Quiet morning.")
                .font(.system(size: 18, weight: .semibold))
            Text("Log a session and it'll show up here.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Couldn't load the feed.")
                .font(.system(size: 16, weight: .semibold))
            if let msg = errorMessage {
                Text(msg)
                    .font(.system(size: 13))
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
        guard service.forYouPosts.isEmpty else { return }
        await refresh()
    }

    private func refresh() async {
        do {
            try await service.loadForYou(refresh: true)
            loadFailed = false
            errorMessage = nil
        } catch {
            loadFailed = true
            errorMessage = (error as? APIError)?.userMessage ?? "Try again in a moment."
        }
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
