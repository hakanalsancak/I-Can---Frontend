import SwiftUI

struct ChatSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var total = 0
    @State private var searchText = ""

    @State private var renamingConversation: Conversation?
    @State private var renameText = ""
    @State private var showRenameAlert = false

    @State private var deletingConversation: Conversation?
    @State private var showDeleteConfirmation = false

    var currentConversationId: String?
    var onSelectConversation: (String) -> Void
    var onNewChat: () -> Void
    var onClose: () -> Void

    private let coachGradient = [Color(hex: "0EA5E9"), Color(hex: "22C55E")]
    private let pageSize = 20

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            newChatButton

            if isLoading && conversations.isEmpty {
                loadingState
            } else if filteredConversations.isEmpty {
                emptyState
            } else {
                conversationsList
            }
        }
        .background(ColorTheme.background(colorScheme).ignoresSafeArea())
        .task {
            if conversations.isEmpty {
                await loadConversations(reset: true)
            }
        }
        .alert("Rename Conversation", isPresented: $showRenameAlert) {
            TextField("Conversation name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renamingConversation = nil
            }
            Button("Save") {
                if let conversation = renamingConversation {
                    Task { await renameConversation(conversation, newTitle: renameText) }
                }
            }
        }
        .alert("Delete Conversation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                deletingConversation = nil
            }
            Button("Delete", role: .destructive) {
                if let conversation = deletingConversation {
                    Task { await deleteConversation(conversation) }
                }
            }
        } message: {
            Text("Are you sure you want to delete this conversation? This cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("AI Coach")
                .font(.system(size: 22, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Spacer()

            Button {
                HapticManager.impact(.light)
                onClose()
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .frame(width: 36, height: 36)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            TextField("Search conversations", text: $searchText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - New Chat Button

    private var newChatButton: some View {
        Button {
            HapticManager.impact(.light)
            onNewChat()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("New Chat")
                    .font(.system(size: 15, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Filtered Conversations

    private var filteredConversations: [Conversation] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return conversations }
        return conversations.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(trimmed) ||
            ($0.lastMessage ?? "").localizedCaseInsensitiveContains(trimmed)
        }
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
        VStack(spacing: 12) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "0EA5E9").opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 42
                        )
                    )
                    .frame(width: 86, height: 86)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            Text(searchText.isEmpty ? "No Conversations Yet" : "No matches")
                .font(.system(size: 16, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text(searchText.isEmpty ? "Start chatting to see\nyour history here." : "Try a different search.")
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        List {
            let pinned = filteredConversations.filter(\.isPinned)
            let recent = filteredConversations.filter { !$0.isPinned }

            if !pinned.isEmpty {
                Section {
                    ForEach(pinned) { conversation in
                        conversationRow(conversation)
                            .listRowConfig(self, conversation: conversation)
                    }
                } header: {
                    sectionHeader("Pinned")
                }
            }

            if !recent.isEmpty {
                Section {
                    ForEach(recent) { conversation in
                        conversationRow(conversation)
                            .listRowConfig(self, conversation: conversation)
                    }
                } header: {
                    sectionHeader(pinned.isEmpty ? "Recents" : "Recents")
                }
            }

            if hasMore && !isLoading && searchText.isEmpty {
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

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold).width(.condensed))
            .foregroundColor(ColorTheme.secondaryText(colorScheme))
            .textCase(.uppercase)
            .padding(.leading, 4)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }

    @ViewBuilder
    fileprivate func conversationRow(_ conversation: Conversation) -> some View {
        let isActive = conversation.id == currentConversationId
        Button {
            HapticManager.impact(.light)
            onSelectConversation(conversation.id)
        } label: {
            HStack(spacing: 10) {
                if conversation.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(conversation.title ?? "New Conversation")
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .lineLimit(1)

                    if let lastMessage = conversation.lastMessage, !lastMessage.isEmpty {
                        Text(lastMessage)
                            .font(.system(size: 12, weight: .regular).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(timeAgoText(conversation.updatedAt))
                    .font(.system(size: 11, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isActive
                    ? Color(hex: "0EA5E9").opacity(0.10)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadConversations(reset: Bool) async {
        guard !isLoading else { return }
        isLoading = true

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
            print("ChatSidebarView: failed to load conversations - \(error.localizedDescription)")
            #endif
        }

        isLoading = false
    }

    private func loadMore() async {
        guard hasMore, !isLoading else { return }
        await loadConversations(reset: false)
    }

    fileprivate func renameConversation(_ conversation: Conversation, newTitle: String) async {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await ChatService.shared.renameConversation(conversation.id, title: trimmed)
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                withAnimation(.easeOut(duration: 0.2)) {
                    conversations[index].title = trimmed
                }
            }
            HapticManager.impact(.light)
        } catch {
            #if DEBUG
            print("ChatSidebarView: failed to rename conversation - \(error.localizedDescription)")
            #endif
        }
        renamingConversation = nil
    }

    fileprivate func togglePin(_ conversation: Conversation) async {
        do {
            let isPinned = try await ChatService.shared.togglePin(conversation.id)
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                withAnimation(.easeOut(duration: 0.25)) {
                    conversations[index].isPinned = isPinned
                    conversations.sort { a, b in
                        if a.isPinned != b.isPinned { return a.isPinned }
                        return a.updatedAt > b.updatedAt
                    }
                }
            }
            HapticManager.impact(.light)
        } catch {
            #if DEBUG
            print("ChatSidebarView: failed to toggle pin - \(error.localizedDescription)")
            #endif
        }
    }

    fileprivate func deleteConversation(_ conversation: Conversation) async {
        do {
            try await ChatService.shared.deleteConversation(conversation.id)
            withAnimation(.easeOut(duration: 0.25)) {
                conversations.removeAll { $0.id == conversation.id }
                total = max(total - 1, 0)
            }
            HapticManager.impact(.light)
        } catch {
            #if DEBUG
            print("ChatSidebarView: failed to delete conversation - \(error.localizedDescription)")
            #endif
        }
        deletingConversation = nil
    }

    fileprivate func beginRename(_ conversation: Conversation) {
        renamingConversation = conversation
        renameText = conversation.title ?? ""
        showRenameAlert = true
    }

    fileprivate func confirmDelete(_ conversation: Conversation) {
        deletingConversation = conversation
        showDeleteConfirmation = true
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

private extension View {
    func listRowConfig(_ sidebar: ChatSidebarView, conversation: Conversation) -> some View {
        self
            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    Task { await sidebar.deleteConversation(conversation) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Task { await sidebar.togglePin(conversation) }
                } label: {
                    Label(
                        conversation.isPinned ? "Unpin" : "Pin",
                        systemImage: conversation.isPinned ? "pin.slash.fill" : "pin.fill"
                    )
                }
                .tint(Color(hex: "F59E0B"))
            }
            .contextMenu {
                Button {
                    sidebar.beginRename(conversation)
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button {
                    Task { await sidebar.togglePin(conversation) }
                } label: {
                    Label(
                        conversation.isPinned ? "Unpin" : "Pin",
                        systemImage: conversation.isPinned ? "pin.slash" : "pin"
                    )
                }

                Divider()

                Button(role: .destructive) {
                    sidebar.confirmDelete(conversation)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}
