import SwiftUI

struct InboxView: View {
    @State private var service = DMService.shared
    @State private var loadFailed = false
    @State private var errorMessage: String?

    @State private var query: String = ""
    @State private var filter: InboxFilter = .all
    @State private var pendingDeleteId: String?
    @State private var deepLinkConversation: DMConversation?
    @FocusState private var searchFieldFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await initialLoad() }
        .refreshable { await refresh() }
        .alert("Delete chat?", isPresented: deleteAlertBinding, presenting: pendingDeleteId) { id in
            Button("Cancel", role: .cancel) { pendingDeleteId = nil }
            Button("Delete", role: .destructive) {
                service.hideConversation(id)
                pendingDeleteId = nil
            }
        } message: { _ in
            Text("Messages will be removed from this device. New messages will bring the chat back.")
        }
        .navigationDestination(item: $deepLinkConversation) { c in
            ChatView(conversation: c)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { note in
            guard let id = note.userInfo?["conversationId"] as? String else { return }
            Task { await openDeepLink(conversationId: id) }
        }
    }

    private func openDeepLink(conversationId id: String) async {
        if let existing = service.conversations.first(where: { $0.id == id }) {
            deepLinkConversation = existing
            return
        }
        // Conversation not yet cached — refresh inbox, then try again.
        try? await service.loadInbox()
        if let found = service.conversations.first(where: { $0.id == id }) {
            deepLinkConversation = found
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteId != nil },
            set: { if !$0 { pendingDeleteId = nil } }
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            searchBar
            filterBar
            Divider().opacity(0.25)
            mainContent(for: filteredAndSorted())
        }
    }

    @ViewBuilder
    private func mainContent(for items: [DMConversation]) -> some View {
        if service.conversations.isEmpty && service.isLoadingInbox {
            loadingState
        } else if service.conversations.isEmpty && loadFailed {
            errorState
        } else if service.visibleConversations.isEmpty {
            emptyState
        } else if items.isEmpty {
            filteredEmptyState
        } else {
            list(items)
        }
    }

    // MARK: - Search & filters

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                TextField("Search messages", text: $query)
                    .focused($searchFieldFocused)
                    .font(.system(size: 15).width(.condensed))
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ColorTheme.elevatedBackground(colorScheme))
            )

            if searchFieldFocused || !query.isEmpty {
                Button("Cancel") {
                    query = ""
                    searchFieldFocused = false
                }
                .font(.system(size: 14, weight: .semibold).width(.condensed))
                .foregroundStyle(ColorTheme.accent)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxFilter.allCases) { f in
                    InboxFilterChip(
                        title: f.title,
                        count: count(for: f),
                        isActive: filter == f
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) { filter = f }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    // MARK: - List

    private func list(_ items: [DMConversation]) -> some View {
        let pinned = items.filter { service.pinnedIds.contains($0.id) }
        let regular = items.filter { !service.pinnedIds.contains($0.id) }
        return List {
            if !pinned.isEmpty {
                Section {
                    ForEach(pinned) { row($0) }
                } header: {
                    sectionHeader(title: "Pinned", icon: "pin.fill")
                }
            }
            if !regular.isEmpty {
                Section {
                    ForEach(regular) { row($0) }
                } header: {
                    if !pinned.isEmpty {
                        sectionHeader(title: "All Chats", icon: nil)
                    } else {
                        Color.clear.frame(height: 0)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.background(colorScheme))
        .environment(\.defaultMinListRowHeight, 0)
    }

    private func sectionHeader(title: String, icon: String?) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold).width(.condensed))
                .tracking(0.6)
            Spacer()
        }
        .foregroundStyle(ColorTheme.secondaryText(colorScheme))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets())
        .background(ColorTheme.background(colorScheme))
    }

    // MARK: - Row

    private func row(_ c: DMConversation) -> some View {
        let isUnread = isUnread(c)
        let isPinned = service.pinnedIds.contains(c.id)
        let isMuted = service.mutedIds.contains(c.id)
        let isArchived = service.archivedIds.contains(c.id)

        return NavigationLink {
            ChatView(conversation: c)
                .onAppear {
                    if service.manualUnreadIds.contains(c.id) {
                        service.setManualUnread(c.id, false)
                    }
                }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                avatar(c)
                    .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(c.displayName)
                            .font(.system(size: 16, weight: isUnread ? .semibold : .medium).width(.condensed))
                            .foregroundStyle(ColorTheme.primaryText(colorScheme))
                            .lineLimit(1)
                        if isMuted {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                        }
                        Spacer(minLength: 6)
                        Text(formatTime(c.lastMessageDate))
                            .font(.system(size: 12, weight: isUnread ? .semibold : .regular).width(.condensed).monospacedDigit())
                            .foregroundStyle(isUnread ? ColorTheme.accent : ColorTheme.tertiaryText(colorScheme))
                    }

                    HStack(spacing: 8) {
                        previewText(for: c, isUnread: isUnread)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        unreadIndicator(c, isUnread: isUnread, isMuted: isMuted, isPinned: isPinned)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .listRowBackground(ColorTheme.background(colorScheme))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                service.togglePin(c.id)
            } label: {
                Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
            }
            .tint(ColorTheme.accent)

            Button {
                let target = !(isUnread)
                service.setManualUnread(c.id, target)
            } label: {
                Label(isUnread ? "Read" : "Unread", systemImage: isUnread ? "envelope.open.fill" : "envelope.badge.fill")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeleteId = c.id
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }

            Button {
                service.setArchived(c.id, !isArchived)
            } label: {
                Label(isArchived ? "Unarchive" : "Archive", systemImage: isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill")
            }
            .tint(.gray)

            Button {
                service.toggleMute(c.id)
            } label: {
                Label(isMuted ? "Unmute" : "Mute", systemImage: isMuted ? "bell.fill" : "bell.slash.fill")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                service.togglePin(c.id)
            } label: {
                Label(isPinned ? "Unpin from top" : "Pin to top",
                      systemImage: isPinned ? "pin.slash" : "pin")
            }
            Button {
                let target = !(isUnread)
                service.setManualUnread(c.id, target)
            } label: {
                Label(isUnread ? "Mark as read" : "Mark as unread",
                      systemImage: isUnread ? "envelope.open" : "envelope.badge")
            }
            Button {
                service.toggleMute(c.id)
            } label: {
                Label(isMuted ? "Unmute" : "Mute",
                      systemImage: isMuted ? "bell" : "bell.slash")
            }
            Button {
                service.setArchived(c.id, !isArchived)
            } label: {
                Label(isArchived ? "Unarchive" : "Archive",
                      systemImage: isArchived ? "tray.and.arrow.up" : "archivebox")
            }
            Divider()
            Button(role: .destructive) {
                pendingDeleteId = c.id
            } label: {
                Label("Delete chat", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func unreadIndicator(_ c: DMConversation, isUnread: Bool, isMuted: Bool, isPinned: Bool) -> some View {
        let badgeCount = effectiveUnreadCount(c)
        HStack(spacing: 6) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .rotationEffect(.degrees(45))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
            }
            if isUnread {
                if badgeCount > 0 {
                    Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                        .font(.system(size: 11, weight: .bold).width(.condensed).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isMuted ? Color.gray : ColorTheme.accent)
                        )
                } else {
                    Circle()
                        .fill(isMuted ? Color.gray : ColorTheme.accent)
                        .frame(width: 9, height: 9)
                }
            }
        }
    }

    private func previewText(for c: DMConversation, isUnread: Bool) -> some View {
        let primary: Color = isUnread
            ? ColorTheme.primaryText(colorScheme)
            : ColorTheme.secondaryText(colorScheme)

        if let lm = c.lastMessage {
            let mine = lm.senderId == AuthService.shared.currentUser?.id
            let preview = previewBody(lm.body)
            return AnyView(
                (
                    Text(mine ? "You: " : "")
                        .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                    + Text(preview)
                        .foregroundStyle(primary)
                )
                .font(.system(size: 14, weight: isUnread ? .medium : .regular).width(.condensed))
            )
        } else {
            return AnyView(
                Text("Tap to start the conversation")
                    .font(.system(size: 14).width(.condensed))
                    .italic()
                    .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
            )
        }
    }

    private func previewBody(_ body: String) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Attachment" }
        return trimmed
    }

    @ViewBuilder
    private func avatar(_ c: DMConversation) -> some View {
        ZStack {
            if let s = c.other?.photoUrl, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        avatarInitials(c.displayName)
                    }
                }
                .clipShape(Circle())
            } else {
                avatarInitials(c.displayName)
            }
        }
        .overlay(
            Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5)
        )
    }

    private func avatarInitials(_ name: String) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: avatarGradient(for: name),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(initials(name))
                    .font(.system(size: 18, weight: .semibold).width(.condensed))
                    .foregroundStyle(.white)
            )
    }

    private func avatarGradient(for name: String) -> [Color] {
        let palettes: [[Color]] = [
            [Color(hex: "42AAB1"), Color(hex: "2F7E84")],
            [Color(hex: "F97316"), Color(hex: "EA580C")],
            [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
            [Color(hex: "22C55E"), Color(hex: "15803D")],
            [Color(hex: "EC4899"), Color(hex: "BE185D")],
            [Color(hex: "0EA5E9"), Color(hex: "0369A1")]
        ]
        let idx = abs(name.hashValue) % palettes.count
        return palettes[idx]
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let s = parts.dropFirst().first?.first.map(String.init) ?? ""
        let combined = (f + s).uppercased()
        return combined.isEmpty ? "?" : combined
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView().tint(ColorTheme.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(ColorTheme.subtleAccent(colorScheme))
                    .frame(width: 84, height: 84)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(ColorTheme.accent)
            }
            Text("No messages yet")
                .font(.system(size: 19, weight: .semibold).width(.condensed))
                .foregroundStyle(ColorTheme.primaryText(colorScheme))
            Text("Connect with athletes after a great session — your conversations will appear here.")
                .font(.system(size: 14).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
            Text(emptyTitle(for: filter))
                .font(.system(size: 16, weight: .semibold).width(.condensed))
                .foregroundStyle(ColorTheme.primaryText(colorScheme))
            Text(emptySubtitle(for: filter))
                .font(.system(size: 13).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
            Text("Couldn't load inbox")
                .font(.system(size: 16, weight: .semibold).width(.condensed))
            if let m = errorMessage {
                Text(m)
                    .font(.system(size: 13).width(.condensed))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button {
                Task { await refresh() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(ColorTheme.accent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter & sort logic

    private func filteredAndSorted() -> [DMConversation] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var items = service.visibleConversations

        switch filter {
        case .all:
            items = items.filter { !service.archivedIds.contains($0.id) }
        case .unread:
            items = items.filter { !service.archivedIds.contains($0.id) && isUnread($0) }
        case .archived:
            items = items.filter { service.archivedIds.contains($0.id) }
        }

        if !q.isEmpty {
            items = items.filter { c in
                if c.displayName.lowercased().contains(q) { return true }
                if let body = c.lastMessage?.body.lowercased(), body.contains(q) { return true }
                if let u = c.other?.username?.lowercased(), u.contains(q) { return true }
                return false
            }
        }

        return items.sorted(by: orderConversations)
    }

    private func orderConversations(_ a: DMConversation, _ b: DMConversation) -> Bool {
        let aPinned = service.pinnedIds.contains(a.id)
        let bPinned = service.pinnedIds.contains(b.id)
        if aPinned != bPinned { return aPinned }
        let aDate = a.lastMessageDate ?? .distantPast
        let bDate = b.lastMessageDate ?? .distantPast
        return aDate > bDate
    }

    private func count(for filter: InboxFilter) -> Int {
        switch filter {
        case .all:
            return service.visibleConversations.filter { !service.archivedIds.contains($0.id) }.count
        case .unread:
            return service.visibleConversations.filter { !service.archivedIds.contains($0.id) && isUnread($0) }.count
        case .archived:
            return service.archivedIds.intersection(service.visibleConversations.map { $0.id }).count
        }
    }

    private func isUnread(_ c: DMConversation) -> Bool {
        if service.manualUnreadIds.contains(c.id) { return true }
        return c.unreadCount > 0
    }

    private func effectiveUnreadCount(_ c: DMConversation) -> Int {
        if service.manualUnreadIds.contains(c.id) && c.unreadCount == 0 { return 0 }
        return c.unreadCount
    }

    private func emptyTitle(for filter: InboxFilter) -> String {
        switch filter {
        case .all: return "No matches"
        case .unread: return "All caught up"
        case .archived: return "Archive empty"
        }
    }

    private func emptySubtitle(for filter: InboxFilter) -> String {
        switch filter {
        case .all: return "Try a different search."
        case .unread: return "You've read every message."
        case .archived: return "Archived conversations will appear here."
        }
    }

    // MARK: - Time formatting

    private func formatTime(_ date: Date?) -> String {
        guard let date else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.locale = .current
            f.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: .current) ?? "HH:mm"
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if let days = cal.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            let f = DateFormatter()
            f.dateFormat = "EEE"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "M/d/yy", options: 0, locale: .current) ?? "M/d/yy"
        return f.string(from: date)
    }

    // MARK: - Loading

    private func initialLoad() async {
        service.reloadLocalState()
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

// MARK: - Filter model

private enum InboxFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .archived: return "Archived"
        }
    }
}

// MARK: - Filter chip

private struct InboxFilterChip: View {
    let title: String
    let count: Int
    let isActive: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                if count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: 11, weight: .bold).width(.condensed).monospacedDigit())
                        .foregroundStyle(isActive ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(
                                isActive
                                    ? Color.white.opacity(0.95)
                                    : ColorTheme.elevatedBackground(colorScheme)
                            )
                        )
                }
            }
            .foregroundStyle(isActive ? .white : ColorTheme.secondaryText(colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isActive ? ColorTheme.accent : ColorTheme.elevatedBackground(colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}
