import SwiftUI

struct ChatHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var total = 0
    @State private var errorMessage: String?

    var onSelectConversation: (String) -> Void
    var onNewChat: () -> Void

    private let coachGradient = [Color(hex: "0EA5E9"), Color(hex: "22C55E")]
    private let pageSize = 20

    var body: some View {
        VStack(spacing: 0) {
            header

            if isLoading && conversations.isEmpty {
                loadingState
            } else if conversations.isEmpty {
                emptyState
            } else {
                conversationsList
            }
        }
        .background(ColorTheme.background(colorScheme).ignoresSafeArea())
        .task {
            await loadConversations(reset: true)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                Spacer()

                Text("Chat History")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Spacer()

                Button {
                    HapticManager.impact(.light)
                    onNewChat()
                    dismiss()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)
        }
        .background(ColorTheme.background(colorScheme))
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Color(hex: "0EA5E9"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "0EA5E9").opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            Text("No Conversations Yet")
                .font(.system(size: 20, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text("Start chatting with your AI Coach\nto see your history here.")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button {
                HapticManager.impact(.light)
                onNewChat()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.bubble.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Start a Conversation")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(colors: coachGradient, startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(hex: "0EA5E9").opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        List {
            ForEach(conversations) { conversation in
                conversationRow(conversation)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await deleteConversation(conversation) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }

            if hasMore && !isLoading {
                Color.clear
                    .frame(height: 1)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        Task { await loadMore() }
                    }
            }

            if isLoading && !conversations.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "0EA5E9"))
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.vertical, 12)
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .refreshable {
            await loadConversations(reset: true)
        }
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        Button {
            HapticManager.impact(.light)
            onSelectConversation(conversation.id)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0EA5E9").opacity(0.12), Color(hex: "22C55E").opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.title ?? "New Conversation")
                            .font(.system(size: 15, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .lineLimit(1)

                        Spacer()

                        Text(timeAgoText(conversation.updatedAt))
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }

                    if let lastMessage = conversation.lastMessage, !lastMessage.isEmpty {
                        Text(lastMessage)
                            .font(.system(size: 13, weight: .regular).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .lineLimit(2)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 10, weight: .medium))
                        Text("\(conversation.messageCount)")
                            .font(.system(size: 11, weight: .medium).width(.condensed))
                    }
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadConversations(reset: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let offset = reset ? 0 : conversations.count
            let response = try await ChatService.shared.fetchConversations(limit: pageSize, offset: offset)
            if reset {
                conversations = response.conversations
            } else {
                conversations.append(contentsOf: response.conversations)
            }
            total = response.total
            hasMore = conversations.count < total
        } catch {
            #if DEBUG
            print("ChatHistoryView: failed to load conversations - \(error.localizedDescription)")
            #endif
            errorMessage = "Failed to load conversations"
        }

        isLoading = false
    }

    private func loadMore() async {
        guard hasMore, !isLoading else { return }
        await loadConversations(reset: false)
    }

    private func deleteConversation(_ conversation: Conversation) async {
        do {
            try await ChatService.shared.deleteConversation(conversation.id)
            withAnimation(.easeOut(duration: 0.25)) {
                conversations.removeAll { $0.id == conversation.id }
                total = max(total - 1, 0)
            }
            HapticManager.impact(.light)
        } catch {
            #if DEBUG
            print("ChatHistoryView: failed to delete conversation - \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Helpers

    private func timeAgoText(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
