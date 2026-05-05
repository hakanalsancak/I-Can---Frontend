import SwiftUI

struct FriendsFeedView: View {
    @State private var service = CommunityService.shared
    @State private var loadFailed = false
    @State private var errorMessage: String?
    @State private var showFriendsManager = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            content
            findFriendsButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await initialLoad() }
        .sheet(isPresented: $showFriendsManager) {
            FriendsView()
        }
    }

    private var findFriendsButton: some View {
        Button {
            showFriendsManager = true
        } label: {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 18))
                .foregroundStyle(ColorTheme.accent)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(ColorTheme.accent.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var content: some View {
        if visibleFriendsPosts.isEmpty && service.friendsLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if visibleFriendsPosts.isEmpty && loadFailed {
            errorState
        } else if visibleFriendsPosts.isEmpty {
            emptyState
        } else {
            feedList
        }
    }

    private var visibleFriendsPosts: [CommunityPost] {
        let mod = ModerationService.shared
        return service.friendsPosts.filter {
            !mod.hiddenPostIds.contains($0.id)
            && !mod.blockedUserIds.contains($0.authorId)
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(visibleFriendsPosts) { post in
                    PostCardView(post: post)
                        .padding(.horizontal, 16)
                        .task { await service.loadMoreFriendsIfNeeded(currentItem: post) }
                }
                if service.friendsLoading && !service.friendsPosts.isEmpty {
                    ProgressView().padding(.vertical, 20)
                }
                Color.clear.frame(height: 80)
            }
            .padding(.top, 12)
        }
        .refreshable { await refresh() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No posts yet.")
                .font(.system(size: 18, weight: .semibold))
            Text("Add training partners to see their work.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Button {
                showFriendsManager = true
            } label: {
                Text("Find friends")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(ColorTheme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Couldn't load the feed.")
                .font(.system(size: 16, weight: .semibold))
            if let m = errorMessage {
                Text(m).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Button("Retry") { Task { await refresh() } }
                .buttonStyle(.borderedProminent)
                .tint(ColorTheme.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func initialLoad() async {
        guard service.friendsPosts.isEmpty else { return }
        await refresh()
    }

    private func refresh() async {
        do {
            try await service.loadFriendsFeed(refresh: true)
            loadFailed = false
            errorMessage = nil
        } catch {
            loadFailed = true
            errorMessage = (error as? APIError)?.errorDescription ?? "Try again."
        }
    }
}
