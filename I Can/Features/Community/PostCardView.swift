import SwiftUI

struct PostCardView: View {
    let post: CommunityPost
    @State private var service = CommunityService.shared
    @State private var moderation = ModerationService.shared
    @State private var likeBusy = false
    @State private var saveBusy = false
    @State private var showReport = false
    @State private var showBlockConfirm = false
    @Environment(\.colorScheme) private var colorScheme

    private var currentUserId: String? { AuthService.shared.currentUser?.id }
    private var isMyPost: Bool { post.authorId == currentUserId }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let badge = typeBadge {
                badgeView(badge)
            }
            if let body = post.body, !body.isEmpty {
                Text(body)
                    .font(.system(size: 15).width(.condensed))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let url = post.photoUrl, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.secondary.opacity(0.1))
                            .aspectRatio(4.0/5.0, contentMode: .fit)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle().fill(Color.secondary.opacity(0.05))
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            footer
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            NavigationLink {
                CommunityProfileView(userId: post.authorId)
            } label: {
                HStack(spacing: 10) {
                    avatar
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.displayName)
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                            .foregroundStyle(.primary)
                        if let sport = post.authorSport {
                            Text(sport.capitalized)
                                .font(.system(size: 12).width(.condensed))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text(relativeTime)
                .font(.system(size: 12).width(.condensed))
                .foregroundStyle(.secondary)
            menuButton
        }
        .sheet(isPresented: $showReport) {
            ReportSheet(targetKind: "post", targetId: post.id) {}
        }
        .alert("Block this user?", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                Task { try? await moderation.block(userId: post.authorId) }
            }
        } message: {
            Text("They won't see your profile or posts. You won't see theirs.")
        }
    }

    private var menuButton: some View {
        Menu {
            if isMyPost {
                Button(role: .destructive) {
                    Task { try? await service.deletePost(id: post.id) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    moderation.hidePost(post.id)
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                }
                Button {
                    showReport = true
                } label: {
                    Label("Report", systemImage: "flag")
                }
                Button(role: .destructive) {
                    showBlockConfirm = true
                } label: {
                    Label("Block user", systemImage: "hand.raised")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let urlString = post.authorPhotoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable()
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials)
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundStyle(ColorTheme.accent)
                )
        }
    }

    private var initials: String {
        let name = post.displayName
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private var typeBadge: String? {
        switch post.type {
        case "pr": return "NEW PR"
        case "streak": return "STREAK"
        case "training_log": return "TRAINING"
        case "progress": return "PROGRESS"
        case "challenge": return "CHALLENGE"
        case "question": return "QUESTION"
        default: return nil
        }
    }

    private func badgeView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold).width(.condensed))
            .tracking(0.5)
            .foregroundStyle(ColorTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(ColorTheme.accent.opacity(0.12))
            )
    }

    private var footer: some View {
        HStack(spacing: 20) {
            Button { Task { await tapLike() } } label: {
                HStack(spacing: 4) {
                    Image(systemName: post.likedByMe ? "heart.fill" : "heart")
                        .foregroundStyle(post.likedByMe ? .red : .secondary)
                        .scaleEffect(post.likedByMe ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6),
                                   value: post.likedByMe)
                    Text("\(post.likeCount)")
                        .font(.system(size: 13).width(.condensed).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(likeBusy)

            NavigationLink {
                PostDetailView(postId: post.id)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(.secondary)
                    Text("\(post.commentCount)")
                        .font(.system(size: 13).width(.condensed).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
            Button { Task { await tapSave() } } label: {
                Image(systemName: post.savedByMe ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(post.savedByMe ? ColorTheme.accent : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(saveBusy)
        }
    }

    private func tapLike() async {
        guard !likeBusy else { return }
        likeBusy = true
        defer { likeBusy = false }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        _ = try? await service.toggleLike(postId: post.id)
    }

    private func tapSave() async {
        guard !saveBusy else { return }
        saveBusy = true
        defer { saveBusy = false }
        _ = try? await service.toggleSave(postId: post.id)
    }

    private var relativeTime: String {
        guard let date = post.createdAtDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
