import SwiftUI

struct ChatView: View {
    let conversation: DMConversation

    @State private var service = DMService.shared
    @State private var messages: [DMMessage] = []
    @State private var draft: String = ""
    @State private var nextCursor: String?
    @State private var hasReachedEnd = false
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var pollTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentUserId: String? = AuthService.shared.currentUser?.id

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            inputBar
        }
        .background(ColorTheme.background(colorScheme).ignoresSafeArea())
        .navigationTitle(conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await initialLoad() }
        .onDisappear { pollTask?.cancel() }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    Color.clear.frame(height: 8).id("topAnchor")
                    ForEach(orderedMessages) { msg in
                        bubble(for: msg)
                            .id(msg.id)
                            .padding(.horizontal, 12)
                            .task { await loadMoreIfNeeded(currentItem: msg) }
                    }
                    if isLoading && !messages.isEmpty {
                        ProgressView().padding(.vertical, 8)
                    }
                    Color.clear.frame(height: 8).id("bottomAnchor")
                }
            }
            .onChange(of: orderedMessages.count) { _, _ in
                if let lastId = orderedMessages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastId = orderedMessages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    private var orderedMessages: [DMMessage] {
        messages.sorted { ($0.createdAtDate ?? .distantPast) < ($1.createdAtDate ?? .distantPast) }
    }

    private func bubble(for msg: DMMessage) -> some View {
        let isMe = msg.senderId == currentUserId
        return HStack {
            if isMe { Spacer(minLength: 40) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.body ?? "")
                    .font(.system(size: 15))
                    .foregroundStyle(isMe ? Color.white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isMe
                                  ? AnyShapeStyle(ColorTheme.accent)
                                  : AnyShapeStyle(Color.secondary.opacity(0.12)))
                    )
                Text(timeString(msg.createdAtDate))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            if !isMe { Spacer(minLength: 40) }
        }
    }

    private func timeString(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: d)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            if let m = errorMessage {
                Text(m)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
            HStack(spacing: 8) {
                TextField("Message", text: $draft, axis: .vertical)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.secondary.opacity(0.10))
                    )
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(canSend ? ColorTheme.accent : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 2000 && !isSending
    }

    private func initialLoad() async {
        await loadOlder(refresh: true)
        await service.markRead(conversationId: conversation.id)
        startPolling()
    }

    private func loadOlder(refresh: Bool) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let cursor = refresh ? nil : nextCursor
            let page = try await service.loadMessages(
                conversationId: conversation.id,
                cursor: cursor
            )
            if refresh {
                messages = page.items
            } else {
                let existing = Set(messages.map(\.id))
                messages.append(contentsOf: page.items.filter { !existing.contains($0.id) })
            }
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
        } catch {
            // silent; let user retry by pulling
        }
    }

    private func loadMoreIfNeeded(currentItem: DMMessage) async {
        guard !hasReachedEnd, !isLoading else { return }
        let ordered = orderedMessages
        guard let idx = ordered.firstIndex(of: currentItem) else { return }
        if idx <= 5 { await loadOlder(refresh: false) }
    }

    private func send() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            let m = try await service.send(conversationId: conversation.id, body: trimmed)
            messages.append(m)
            draft = ""
            errorMessage = nil
            try? await service.loadInbox()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't send."
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { return }
                await pollLatest()
            }
        }
    }

    private func pollLatest() async {
        do {
            let page = try await service.loadMessages(
                conversationId: conversation.id,
                limit: 20
            )
            let existing = Set(messages.map(\.id))
            let newOnes = page.items.filter { !existing.contains($0.id) }
            if !newOnes.isEmpty {
                messages.append(contentsOf: newOnes)
                await service.markRead(conversationId: conversation.id)
            }
        } catch {
            // silent
        }
    }
}
