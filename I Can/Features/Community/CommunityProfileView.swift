import SwiftUI

struct CommunityProfileView: View {
    let userId: String

    @State private var service = CommunityProfileService.shared
    @State private var profile: CommunityProfile?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var followBusy = false
    @State private var messageBusy = false
    @State private var openedConversation: DMConversation?
    @State private var goToChat = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if let profile {
                        header(profile)
                        statsRow(profile.stats)
                        if !profile.isSelf {
                            HStack(spacing: 10) {
                                followButton(profile)
                                messageButton(profile)
                            }
                        }
                        if let bio = profile.bio, !bio.isEmpty {
                            bioBlock(bio)
                        }
                    } else if isLoading {
                        ProgressView().padding(.top, 60)
                    } else if loadFailed {
                        Text("Couldn't load profile.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 60)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .navigationDestination(isPresented: $goToChat) {
            if let conv = openedConversation {
                ChatView(conversation: conv)
            }
        }
    }

    private func messageButton(_ p: CommunityProfile) -> some View {
        Button {
            Task { await openMessage(with: p) }
        } label: {
            Text("Message")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(messageBusy)
    }

    private func openMessage(with p: CommunityProfile) async {
        guard !messageBusy else { return }
        messageBusy = true
        defer { messageBusy = false }
        do {
            let convId = try await DMService.shared.openConversation(with: p.id)
            openedConversation = DMConversation(
                id: convId,
                isGroup: false,
                title: nil,
                isRequest: false,
                lastMessageAt: nil,
                lastReadAt: nil,
                unreadCount: 0,
                other: DMConversationOther(
                    id: p.id,
                    fullName: p.fullName,
                    username: p.handle,
                    photoUrl: p.profilePhotoUrl,
                    sport: p.sport
                ),
                lastMessage: nil
            )
            goToChat = true
        } catch {
            // silent
        }
    }

    private func header(_ p: CommunityProfile) -> some View {
        VStack(spacing: 12) {
            avatar(p)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            Text(p.displayName)
                .font(.system(size: 20, weight: .semibold))
            if let handle = p.handle {
                Text("@\(handle)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                if let sport = p.sport {
                    Text(sport.capitalized)
                }
                if let pos = p.position {
                    Text("·")
                    Text(pos)
                }
                if let c = p.country {
                    Text("·")
                    Text(c.uppercased())
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func avatar(_ p: CommunityProfile) -> some View {
        if let urlString = p.profilePhotoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
        } else {
            Circle()
                .fill(ColorTheme.accent.opacity(0.2))
                .overlay(
                    Text(initials(for: p))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(ColorTheme.accent)
                )
        }
    }

    private func initials(for p: CommunityProfile) -> String {
        let parts = p.displayName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private func statsRow(_ s: CommunityProfileStats) -> some View {
        HStack(spacing: 0) {
            statCell(value: s.currentStreak, label: "Day streak")
            divider
            statCell(value: s.totalSessions, label: "Sessions")
            divider
            statCell(value: s.followerCount, label: "Followers")
            divider
            statCell(value: s.followingCount, label: "Following")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 1, height: 28)
    }

    private func followButton(_ p: CommunityProfile) -> some View {
        Button {
            Task { await toggleFollow(p) }
        } label: {
            Text(p.relation.isFollowing ? "Following" : "Follow")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(p.relation.isFollowing ? Color.primary : Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(p.relation.isFollowing
                              ? Color.secondary.opacity(0.15)
                              : ColorTheme.accent)
                )
        }
        .buttonStyle(.plain)
        .disabled(followBusy)
    }

    private func bioBlock(_ bio: String) -> some View {
        Text(bio)
            .font(.system(size: 14))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private func load() async {
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            profile = try await service.loadProfile(userId: userId)
        } catch {
            loadFailed = true
        }
    }

    private func toggleFollow(_ p: CommunityProfile) async {
        guard !followBusy else { return }
        followBusy = true
        defer { followBusy = false }
        do {
            if p.relation.isFollowing {
                _ = try await service.unfollow(userId: p.id)
            } else {
                _ = try await service.follow(userId: p.id)
            }
            profile = service.profileCache[p.id] ?? profile
        } catch {
            // Silent — UI keeps current state
        }
    }
}
