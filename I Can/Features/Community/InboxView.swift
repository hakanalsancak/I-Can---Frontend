import SwiftUI

struct InboxView: View {
    @State private var service = DMService.shared
    @State private var loadFailed = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await initialLoad() }
        .refreshable { await refresh() }
    }

    @ViewBuilder
    private var content: some View {
        if service.conversations.isEmpty && service.isLoadingInbox {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if service.conversations.isEmpty && loadFailed {
            errorState
        } else if service.conversations.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(service.conversations) { conv in
                    NavigationLink {
                        ChatView(conversation: conv)
                    } label: {
                        row(conv)
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.2).padding(.leading, 70)
                }
            }
            .padding(.top, 8)
        }
    }

    private func row(_ c: DMConversation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            avatar(c)
                .frame(width: 46, height: 46)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(c.displayName)
                        .font(.system(size: 15, weight: c.unreadCount > 0 ? .semibold : .regular))
                        .lineLimit(1)
                    Spacer()
                    Text(relativeTime(c.lastMessageDate))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                if let lm = c.lastMessage {
                    Text(lm.body)
                        .font(.system(size: 13))
                        .foregroundStyle(c.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(2)
                } else {
                    Text("Say hi.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            if c.unreadCount > 0 {
                Circle()
                    .fill(ColorTheme.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func avatar(_ c: DMConversation) -> some View {
        if let s = c.other?.photoUrl, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
        } else {
            Circle()
                .fill(ColorTheme.accent.opacity(0.2))
                .overlay(
                    Text(initials(c.displayName))
                        .font(.system(size: 15, weight: .semibold))
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

    private func relativeTime(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No messages.")
                .font(.system(size: 18, weight: .semibold))
            Text("Reach out to someone after a good session.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Couldn't load inbox.")
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
        if service.conversations.isEmpty {
            await refresh()
        }
    }

    private func refresh() async {
        do {
            try await service.loadInbox()
            loadFailed = false
            errorMessage = nil
        } catch {
            loadFailed = true
            errorMessage = (error as? APIError)?.errorDescription ?? "Try again."
        }
    }
}
