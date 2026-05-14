import SwiftUI
import PhotosUI

/// Two-step modal: pick friends → name the group + optional photo → create.
/// Mirrors the WhatsApp "New group" flow.
struct NewGroupView: View {
    let onCreated: (DMConversation) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var friends: [AthleteProfile] = []
    @State private var isLoadingFriends = true
    @State private var friendsError: String?

    @State private var query: String = ""
    @State private var selectedIds: Set<String> = []

    @State private var step: Step = .pickFriends
    @State private var title: String = ""
    @State private var titleErrorShown = false

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoUrl: String?
    @State private var isUploadingPhoto = false

    @State private var isCreating = false
    @State private var createError: String?

    private enum Step { case pickFriends, configure }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()
                switch step {
                case .pickFriends: pickFriendsContent
                case .configure:   configureContent
                }
            }
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(step == .pickFriends ? "New Group" : "Group Info")
            .task { await loadFriends() }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(step == .pickFriends ? "Cancel" : "Back") {
                if step == .pickFriends { dismiss() }
                else { withAnimation { step = .pickFriends } }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            switch step {
            case .pickFriends:
                Button("Next") {
                    withAnimation { step = .configure }
                }
                .disabled(selectedIds.isEmpty)
                .fontWeight(.semibold)
            case .configure:
                Button(isCreating ? "Creating…" : "Create") {
                    Task { await createGroup() }
                }
                .disabled(!canCreate || isCreating)
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Step 1: pick friends

    private var pickFriendsContent: some View {
        VStack(spacing: 0) {
            searchBar
            selectedStrip
            Divider().opacity(0.25)
            friendsList
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .font(.system(size: 14, weight: .semibold))
            TextField("Search friends", text: $query)
                .font(.system(size: 15).width(.condensed))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ColorTheme.elevatedBackground(colorScheme))
        )
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 6)
    }

    @ViewBuilder
    private var selectedStrip: some View {
        if !selectedIds.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedFriends, id: \.id) { f in
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                avatar(for: f, size: 48)
                                Button {
                                    selectedIds.remove(f.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white, Color.black.opacity(0.7))
                                        .background(Circle().fill(.white).frame(width: 12, height: 12))
                                }
                                .buttonStyle(.plain)
                                .offset(x: 4, y: -4)
                            }
                            Text(f.fullName ?? f.username ?? "")
                                .font(.system(size: 11).width(.condensed))
                                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                                .lineLimit(1)
                                .frame(maxWidth: 60)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
            .background(ColorTheme.elevatedBackground(colorScheme).opacity(0.5))
        }
    }

    @ViewBuilder
    private var friendsList: some View {
        if isLoadingFriends {
            VStack { Spacer(); ProgressView().tint(ColorTheme.accent); Spacer() }
        } else if let err = friendsError {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "wifi.exclamationmark").font(.system(size: 28))
                Text(err).font(.system(size: 13).width(.condensed))
                    .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                Button("Retry") { Task { await loadFriends() } }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else if friends.isEmpty {
            emptyFriendsState
        } else {
            let filtered = filteredFriends()
            List(filtered, id: \.id) { f in
                friendRow(f)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(ColorTheme.background(colorScheme))
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture { toggle(f.id) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyFriendsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 32))
                .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
            Text("No friends yet")
                .font(.system(size: 16, weight: .semibold).width(.condensed))
            Text("Add friends first — only your friends can be invited to a group.")
                .font(.system(size: 13).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func friendRow(_ f: AthleteProfile) -> some View {
        let isSelected = selectedIds.contains(f.id)
        return HStack(spacing: 12) {
            avatar(for: f, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(f.fullName ?? f.username ?? "Athlete")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                    .foregroundStyle(ColorTheme.primaryText(colorScheme))
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

    // MARK: - Step 2: configure

    private var configureContent: some View {
        ScrollView {
            VStack(spacing: 22) {
                groupAvatarPicker
                groupNameField
                membersPreview
                if let createError {
                    Text(createError)
                        .font(.system(size: 13).width(.condensed))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
    }

    private var groupAvatarPicker: some View {
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            ZStack {
                Circle()
                    .fill(ColorTheme.elevatedBackground(colorScheme))
                    .frame(width: 96, height: 96)
                if let data = photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(ColorTheme.accent)
                        Text("Add Photo")
                            .font(.system(size: 10, weight: .semibold).width(.condensed))
                            .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                    }
                }
                if isUploadingPhoto {
                    Circle().fill(Color.black.opacity(0.4)).frame(width: 96, height: 96)
                    ProgressView().tint(.white)
                }
            }
            .overlay(Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task { await handlePicked(item) }
        }
    }

    private var groupNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("GROUP NAME")
                .font(.system(size: 11, weight: .semibold).width(.condensed))
                .tracking(0.6)
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
            TextField("e.g. Saturday Run Club", text: $title)
                .font(.system(size: 16).width(.condensed))
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ColorTheme.elevatedBackground(colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(titleErrorShown ? Color.red.opacity(0.5) : ColorTheme.separator(colorScheme),
                                lineWidth: 0.5)
                )
            Text("\(title.count)/60")
                .font(.system(size: 11).width(.condensed).monospacedDigit())
                .foregroundStyle(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(.horizontal, 24)
    }

    private var membersPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(selectedIds.count) MEMBER\(selectedIds.count == 1 ? "" : "S")")
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                    .tracking(0.6)
                Spacer()
            }
            .foregroundStyle(ColorTheme.secondaryText(colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedFriends, id: \.id) { f in
                        VStack(spacing: 4) {
                            avatar(for: f, size: 44)
                            Text(f.fullName?.split(separator: " ").first.map(String.init)
                                 ?? f.username ?? "")
                                .font(.system(size: 11).width(.condensed))
                                .lineLimit(1)
                                .frame(maxWidth: 60)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private var selectedFriends: [AthleteProfile] {
        friends.filter { selectedIds.contains($0.id) }
    }

    private var canCreate: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !selectedIds.isEmpty
    }

    private func filteredFriends() -> [AthleteProfile] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return friends }
        return friends.filter { f in
            if let n = f.fullName?.lowercased(), n.contains(q) { return true }
            if let u = f.username?.lowercased(), u.contains(q) { return true }
            return false
        }
    }

    private func toggle(_ id: String) {
        if selectedIds.contains(id) { selectedIds.remove(id) }
        else { selectedIds.insert(id) }
    }

    @ViewBuilder
    private func avatar(for f: AthleteProfile, size: CGFloat) -> some View {
        ZStack {
            if let s = f.profilePhotoUrl, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { initialsCircle(f) }
                }
            } else {
                initialsCircle(f)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5))
    }

    private func initialsCircle(_ f: AthleteProfile) -> some View {
        let name = f.fullName ?? f.username ?? "?"
        return Circle()
            .fill(ColorTheme.accentGradient)
            .overlay(
                Text(initials(name))
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
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

    private func loadFriends() async {
        isLoadingFriends = true
        defer { isLoadingFriends = false }
        do {
            friends = try await FriendService.shared.getFriends()
            friendsError = nil
        } catch {
            friendsError = (error as? APIError)?.errorDescription ?? "Couldn't load friends."
        }
    }

    private func handlePicked(_ item: PhotosPickerItem) async {
        defer { photoPickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoData = data
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        do {
            photoUrl = try await DMService.shared.uploadGroupPhoto(data: data)
        } catch {
            createError = "Couldn't upload photo. You can still create the group."
            photoData = nil
            photoUrl = nil
        }
    }

    private func createGroup() async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleErrorShown = true
            return
        }
        isCreating = true
        defer { isCreating = false }
        do {
            let id = try await DMService.shared.createGroup(
                title: trimmed,
                memberIds: Array(selectedIds),
                photoUrl: photoUrl
            )
            // Pull the freshly-loaded conversation out of the inbox so the
            // caller can navigate straight into it.
            if let conv = DMService.shared.conversations.first(where: { $0.id == id }) {
                onCreated(conv)
            }
            dismiss()
        } catch {
            createError = (error as? APIError)?.errorDescription ?? "Couldn't create the group."
        }
    }
}
