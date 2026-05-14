import SwiftUI
import PhotosUI

/// Group settings + members screen. Equivalent to WhatsApp's "Group info".
/// Admins get edit/add/remove/promote controls; regular members see a
/// read-only roster with a Leave option.
struct GroupInfoView: View {
    let conversationId: String
    /// Closure used to refresh the parent ChatView's view of the conversation
    /// (e.g. the header avatar/title) without forcing a full inbox reload.
    let onChange: ((DMConversation) -> Void)?
    let onLeft: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var info: DMGroupInfo?
    @State private var isLoading = true
    @State private var loadError: String?

    @State private var renaming = false
    @State private var renameText: String = ""

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var photoUploading = false

    @State private var showAddMembers = false
    @State private var pendingRemove: DMGroupMember?
    @State private var showLeaveConfirm = false
    @State private var actionError: String?

    private var isAdmin: Bool { info?.viewerRole == .admin }
    private var currentUserId: String? { AuthService.shared.currentUser?.id }

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            content
        }
        .navigationTitle("Group Info")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $renaming) { renameSheet }
        .sheet(isPresented: $showAddMembers) {
            if let info {
                AddGroupMembersView(
                    conversationId: conversationId,
                    existingMemberIds: Set(info.members.map(\.id))
                ) {
                    Task { await load() }
                }
            }
        }
        .confirmationDialog(
            "Remove \(pendingRemove?.displayName ?? "member") from group?",
            isPresented: removeConfirmBinding,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let m = pendingRemove {
                    Task { await removeMember(m) }
                }
                pendingRemove = nil
            }
            Button("Cancel", role: .cancel) { pendingRemove = nil }
        }
        .confirmationDialog(
            "Leave this group?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) { Task { await leaveGroup() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll stop receiving messages from this group.")
        }
    }

    private var removeConfirmBinding: Binding<Bool> {
        Binding(
            get: { pendingRemove != nil },
            set: { if !$0 { pendingRemove = nil } }
        )
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && info == nil {
            VStack { Spacer(); ProgressView().tint(ColorTheme.accent); Spacer() }
        } else if let err = loadError, info == nil {
            errorState(err)
        } else if let info {
            ScrollView {
                VStack(spacing: 16) {
                    header(info)
                    if let actionError {
                        Text(actionError)
                            .font(.system(size: 12).width(.condensed))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }
                    membersSection(info)
                    dangerZone(info)
                    Color.clear.frame(height: 40)
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Header

    private func header(_ info: DMGroupInfo) -> some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                groupAvatar(info: info, size: 112)
                if isAdmin {
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Circle()
                            .fill(ColorTheme.accent)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .overlay(Circle().strokeBorder(ColorTheme.background(colorScheme), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .onChange(of: photoPickerItem) { _, item in
                        guard let item else { return }
                        Task { await uploadPhoto(item) }
                    }
                }
                if photoUploading {
                    Circle().fill(Color.black.opacity(0.4)).frame(width: 112, height: 112)
                    ProgressView().tint(.white)
                }
            }

            HStack(spacing: 6) {
                Text(info.title ?? "Group")
                    .font(.system(size: 22, weight: .bold).width(.condensed))
                    .foregroundStyle(ColorTheme.primaryText(colorScheme))
                if isAdmin {
                    Button {
                        renameText = info.title ?? ""
                        renaming = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ColorTheme.accent)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("\(info.members.count) member\(info.members.count == 1 ? "" : "s")")
                .font(.system(size: 13).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
        }
    }

    // MARK: - Members

    private func membersSection(_ info: DMGroupInfo) -> some View {
        VStack(spacing: 0) {
            sectionHeader("MEMBERS")
            VStack(spacing: 0) {
                if isAdmin {
                    Button {
                        showAddMembers = true
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(ColorTheme.accent.opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(ColorTheme.accent)
                                )
                            Text("Add member")
                                .font(.system(size: 15, weight: .medium).width(.condensed))
                                .foregroundStyle(ColorTheme.accent)
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 68).opacity(0.4)
                }
                ForEach(info.members) { m in
                    memberRow(m, info: info)
                    if m.id != info.members.last?.id {
                        Divider().padding(.leading, 68).opacity(0.4)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ColorTheme.cardBackground(colorScheme))
            )
            .padding(.horizontal, 16)
        }
    }

    private func memberRow(_ m: DMGroupMember, info: DMGroupInfo) -> some View {
        let isSelf = m.id == currentUserId
        let canManage = isAdmin && !isSelf
        return Menu {
            if canManage {
                if m.role == .admin {
                    Button {
                        Task { await setRole(m, role: .member) }
                    } label: {
                        Label("Dismiss as admin", systemImage: "person.fill.xmark")
                    }
                } else {
                    Button {
                        Task { await setRole(m, role: .admin) }
                    } label: {
                        Label("Make admin", systemImage: "crown")
                    }
                }
                Button(role: .destructive) {
                    pendingRemove = m
                } label: {
                    Label("Remove from group", systemImage: "trash")
                }
            } else {
                Button { } label: {
                    Label(isSelf ? "You" : m.displayName, systemImage: "person")
                }
                .disabled(true)
            }
        } label: {
            HStack(spacing: 12) {
                memberAvatar(m)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(isSelf ? "You" : m.displayName)
                            .font(.system(size: 15, weight: .medium).width(.condensed))
                            .foregroundStyle(ColorTheme.primaryText(colorScheme))
                            .lineLimit(1)
                        if m.id == info.creatorId {
                            roleBadge("creator", color: ColorTheme.accent)
                        } else if m.role == .admin {
                            roleBadge("admin", color: Color(red: 0.42, green: 0.55, blue: 0.95))
                        }
                    }
                    if let u = m.username, !u.isEmpty {
                        Text("@\(u)")
                            .font(.system(size: 12).width(.condensed))
                            .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                    }
                }
                Spacer()
                if canManage {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func roleBadge(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold).width(.condensed))
            .tracking(0.4)
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
    }

    @ViewBuilder
    private func memberAvatar(_ m: DMGroupMember) -> some View {
        ZStack {
            if let s = m.photoUrl, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { memberInitials(m) }
                }
            } else {
                memberInitials(m)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5))
    }

    private func memberInitials(_ m: DMGroupMember) -> some View {
        let name = m.displayName
        return Circle()
            .fill(ColorTheme.accentGradient)
            .overlay(
                Text(initials(name))
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Danger zone

    private func dangerZone(_ info: DMGroupInfo) -> some View {
        VStack(spacing: 0) {
            Button {
                showLeaveConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Leave group")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                    Spacer()
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ColorTheme.cardBackground(colorScheme))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Rename sheet

    private var renameSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Group name", text: $renameText)
                    .font(.system(size: 17).width(.condensed))
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(ColorTheme.elevatedBackground(colorScheme))
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                Spacer()
            }
            .navigationTitle("Rename group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { renaming = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await rename() }
                    }
                    .fontWeight(.semibold)
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .semibold).width(.condensed))
                .tracking(0.6)
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
            Spacer()
        }
        .padding(.horizontal, 24).padding(.bottom, 6)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
            Text(message)
                .font(.system(size: 14).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Retry") { Task { await load() } }
                .buttonStyle(.plain)
                .foregroundStyle(ColorTheme.accent)
            Spacer()
        }
    }

    @ViewBuilder
    private func groupAvatar(info: DMGroupInfo, size: CGFloat) -> some View {
        ZStack {
            if let s = info.photoUrl, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { groupInitialsAvatar(info.title ?? "G") }
                }
            } else {
                groupInitialsAvatar(info.title ?? "G")
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5))
    }

    private func groupInitialsAvatar(_ name: String) -> some View {
        Circle()
            .fill(ColorTheme.accentGradient)
            .overlay(
                Text(initials(name))
                    .font(.system(size: 36, weight: .semibold).width(.condensed))
                    .foregroundStyle(.white)
            )
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let s = parts.dropFirst().first?.first.map(String.init) ?? ""
        let combined = (f + s).uppercased()
        return combined.isEmpty ? "?" : combined
    }

    // MARK: - Network

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            info = try await DMService.shared.fetchGroupInfo(conversationId: conversationId)
            loadError = nil
            notifyChange()
        } catch {
            loadError = (error as? APIError)?.errorDescription ?? "Couldn't load group."
        }
    }

    private func rename() async {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        renaming = false
        do {
            try await DMService.shared.updateGroup(conversationId: conversationId, title: trimmed)
            try? await DMService.shared.loadInbox()
            await load()
        } catch {
            actionError = (error as? APIError)?.errorDescription ?? "Couldn't rename."
        }
    }

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        defer { photoPickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoUploading = true
        defer { photoUploading = false }
        do {
            let url = try await DMService.shared.uploadGroupPhoto(data: data)
            try await DMService.shared.updateGroup(conversationId: conversationId, photoUrl: .some(url))
            try? await DMService.shared.loadInbox()
            await load()
        } catch {
            actionError = (error as? APIError)?.errorDescription ?? "Couldn't update photo."
        }
    }

    private func removeMember(_ m: DMGroupMember) async {
        do {
            try await DMService.shared.removeMember(conversationId: conversationId, userId: m.id)
            await load()
        } catch {
            actionError = (error as? APIError)?.errorDescription ?? "Couldn't remove."
        }
    }

    private func setRole(_ m: DMGroupMember, role: DMGroupRole) async {
        do {
            try await DMService.shared.setMemberRole(
                conversationId: conversationId, userId: m.id, role: role
            )
            await load()
        } catch {
            actionError = (error as? APIError)?.errorDescription ?? "Couldn't update role."
        }
    }

    private func leaveGroup() async {
        do {
            try await DMService.shared.leaveGroup(conversationId: conversationId)
            onLeft()
            dismiss()
        } catch {
            actionError = (error as? APIError)?.errorDescription ?? "Couldn't leave."
        }
    }

    private func notifyChange() {
        guard let onChange,
              let updated = DMService.shared.conversations.first(where: { $0.id == conversationId })
        else { return }
        onChange(updated)
    }
}

// MARK: - Add members modal

struct AddGroupMembersView: View {
    let conversationId: String
    let existingMemberIds: Set<String>
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var friends: [AthleteProfile] = []
    @State private var isLoading = true
    @State private var query = ""
    @State private var selected: Set<String> = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()
                content
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Adding…" : "Add") {
                        Task { await submit() }
                    }
                    .fontWeight(.semibold)
                    .disabled(selected.isEmpty || isSubmitting)
                }
            }
            .task { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                TextField("Search friends", text: $query)
                    .font(.system(size: 15).width(.condensed))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(ColorTheme.elevatedBackground(colorScheme))
            )
            .padding(.horizontal, 16).padding(.vertical, 10)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12).width(.condensed))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
            }

            if isLoading {
                VStack { Spacer(); ProgressView().tint(ColorTheme.accent); Spacer() }
            } else {
                let avail = available()
                if avail.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Text("No friends available to add.")
                            .font(.system(size: 14).width(.condensed))
                            .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                        Spacer()
                    }
                } else {
                    List(avail, id: \.id) { f in
                        row(f)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(ColorTheme.background(colorScheme))
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selected.contains(f.id) { selected.remove(f.id) }
                                else { selected.insert(f.id) }
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private func available() -> [AthleteProfile] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return friends
            .filter { !existingMemberIds.contains($0.id) }
            .filter { f in
                guard !q.isEmpty else { return true }
                if let n = f.fullName?.lowercased(), n.contains(q) { return true }
                if let u = f.username?.lowercased(), u.contains(q) { return true }
                return false
            }
    }

    private func row(_ f: AthleteProfile) -> some View {
        let isSelected = selected.contains(f.id)
        return HStack(spacing: 12) {
            ZStack {
                if let s = f.profilePhotoUrl, let url = URL(string: s) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image { img.resizable().scaledToFill() }
                        else { initialsAvatar(f) }
                    }
                } else { initialsAvatar(f) }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(f.fullName ?? f.username ?? "Athlete")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                if let u = f.username, !u.isEmpty {
                    Text("@\(u)")
                        .font(.system(size: 12).width(.condensed))
                        .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                }
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(isSelected ? ColorTheme.accent : ColorTheme.separator(colorScheme),
                            lineWidth: isSelected ? 0 : 1.2)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle().fill(ColorTheme.accent).frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func initialsAvatar(_ f: AthleteProfile) -> some View {
        let name = f.fullName ?? f.username ?? "?"
        let parts = name.split(separator: " ")
        let a = parts.first?.first.map(String.init) ?? ""
        let b = parts.dropFirst().first?.first.map(String.init) ?? ""
        return Circle()
            .fill(ColorTheme.accentGradient)
            .overlay(
                Text((a + b).uppercased())
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundStyle(.white)
            )
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try await FriendService.shared.getFriends()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't load friends."
        }
    }

    private func submit() async {
        guard !selected.isEmpty else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await DMService.shared.addMembers(
                conversationId: conversationId, memberIds: Array(selected)
            )
            onAdded()
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't add members."
        }
    }
}
