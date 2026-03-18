import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var selectedProfile: AthleteProfile?
    @State private var searchFocused = false
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Friends")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        searchBar
                            .padding(.horizontal, 20)

                        if !viewModel.searchText.isEmpty {
                            searchResultsSection
                        } else {
                            if !viewModel.pendingRequests.isEmpty {
                                requestsSection
                            }
                            friendsListSection
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { Task { await viewModel.loadAll() } }
            .refreshable { await viewModel.loadAll() }
            .sheet(item: $selectedProfile) { profile in
                AthleteProfileSheet(athleteId: profile.id)
                    .onAppear {
                        AnalyticsManager.log("profile_viewed", parameters: ["athlete_id": profile.id])
                    }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSearchFieldFocused ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))

            TextField("Search by username or name...", text: Binding(
                get: { viewModel.searchText },
                set: { newValue in
                    viewModel.searchText = newValue
                    viewModel.search(query: newValue)
                }
            ))
                .font(.system(size: 16, weight: .medium).width(.condensed))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFieldFocused)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                    isSearchFieldFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSearchFieldFocused ? ColorTheme.accent.opacity(0.5) : ColorTheme.separator(colorScheme),
                    lineWidth: isSearchFieldFocused ? 1.5 : 1
                )
        )
        .shadow(
            color: isSearchFieldFocused ? ColorTheme.accent.opacity(0.15) : .clear,
            radius: 12, x: 0, y: 4
        )
        .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(ColorTheme.accent)
                        .scaleEffect(1.1)
                    Spacer()
                }
                .padding(.top, 48)
            } else if viewModel.searchResults.isEmpty && viewModel.searchText.count >= 2 {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(ColorTheme.cardBackground(colorScheme))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.slash")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.6))
                    }
                    Text("No athletes found")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text("Try a different username or name")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
            } else {
                Text("RESULTS")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                    .tracking(1.2)
                    .padding(.horizontal, 20)

                ForEach(viewModel.searchResults) { user in
                    SearchResultCard(user: user, colorScheme: colorScheme) {
                        Task { await viewModel.sendRequest(to: user.id) }
                    } onTap: {
                        selectedProfile = user
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Requests

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("FRIEND REQUESTS")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                    .tracking(1.2)

                Text("\(viewModel.pendingRequests.count)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ColorTheme.accent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            ForEach(viewModel.pendingRequests) { request in
                FriendRequestCard(
                    request: request,
                    colorScheme: colorScheme,
                    onAccept: { Task { await viewModel.acceptRequest(request) } },
                    onDecline: { Task { await viewModel.declineRequest(request) } }
                ) {
                    selectedProfile = request.sender
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Friends List

    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MY FRIENDS")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                    .tracking(1.2)

                Spacer()

                if !viewModel.friends.isEmpty {
                    Text("\(viewModel.friends.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
            .padding(.horizontal, 20)

            if viewModel.isLoading && viewModel.friends.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(ColorTheme.accent)
                        .scaleEffect(1.1)
                    Spacer()
                }
                .padding(.top, 48)
            } else if viewModel.friends.isEmpty {
                emptyFriendsState
            } else {
                ForEach(viewModel.friends) { friend in
                    FriendCard(friend: friend, colorScheme: colorScheme) {
                        selectedProfile = friend
                    }
                    .padding(.horizontal, 20)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await viewModel.removeFriend(friend) }
                        } label: {
                            Label("Remove Friend", systemImage: "person.badge.minus")
                        }
                    }
                }
            }
        }
    }

    private var emptyFriendsState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(ColorTheme.accent.opacity(0.05))
                    .frame(width: 130, height: 130)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.accent, Color(hex: "358A90")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No friends yet")
                    .font(.system(size: 20, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Search for athletes by username or name\nto connect and track each other's progress")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                isSearchFieldFocused = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text("Find Athletes")
                }
                .font(.system(size: 14, weight: .bold).width(.condensed))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "358A90")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: ColorTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let user: AthleteProfile
    let colorScheme: ColorScheme
    let onAdd: () -> Void
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            RingAvatar(name: user.fullName, photoUrl: user.profilePhotoUrl, size: 48, colorScheme: colorScheme)
                .onTapGesture { onTap() }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.fullName ?? "Athlete")
                    .font(.system(size: 16, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.accent.opacity(0.8))
                }

                if let team = user.team, !team.isEmpty {
                    Text(team)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                }
            }
            .onTapGesture { onTap() }

            Spacer()
                .onTapGesture { onTap() }

            friendStatusButton
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ColorTheme.separator(colorScheme).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private var friendStatusButton: some View {
        let status = user.friendStatus ?? "none"
        switch status {
        case "friends":
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                Text("Friends")
            }
            .font(.system(size: 12, weight: .bold).width(.condensed))
            .foregroundColor(.green)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.green.opacity(0.12))
            .clipShape(Capsule())
        case "pending":
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .bold))
                Text("Pending")
            }
            .font(.system(size: 12, weight: .bold).width(.condensed))
            .foregroundColor(ColorTheme.secondaryText(colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ColorTheme.separator(colorScheme).opacity(0.5))
            .clipShape(Capsule())
        case "incoming":
            Text("Respond")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(ColorTheme.accent.opacity(0.12))
                .clipShape(Capsule())
        default:
            Button {
                HapticManager.impact(.light)
                onAdd()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add")
                }
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "358A90")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: ColorTheme.accent.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Friend Request Card

private struct FriendRequestCard: View {
    let request: FriendRequest
    let colorScheme: ColorScheme
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RingAvatar(name: request.sender.fullName, photoUrl: request.sender.profilePhotoUrl, size: 48, colorScheme: colorScheme)
                .onTapGesture { onTap() }

            VStack(alignment: .leading, spacing: 3) {
                Text(request.sender.fullName ?? "Athlete")
                    .font(.system(size: 16, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let username = request.sender.username {
                    Text("@\(username)")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.accent.opacity(0.8))
                }
            }
            .onTapGesture { onTap() }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    HapticManager.impact(.medium)
                    onAccept()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [ColorTheme.accent, Color(hex: "358A90")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: ColorTheme.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                }

                Button {
                    HapticManager.impact(.light)
                    onDecline()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .frame(width: 38, height: 38)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(Circle())
                        .overlay(
                            Circle().strokeBorder(ColorTheme.separator(colorScheme).opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.accent.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Friend Card

private struct FriendCard: View {
    let friend: AthleteProfile
    let colorScheme: ColorScheme
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.impact(.light)
            onTap()
        } label: {
            HStack(spacing: 14) {
                RingAvatar(name: friend.fullName, photoUrl: friend.profilePhotoUrl, size: 54, colorScheme: colorScheme)

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.fullName ?? "Athlete")
                        .font(.system(size: 17, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    if let username = friend.username {
                        Text("@\(username)")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.accent.opacity(0.8))
                    }

                    if let detail = friendDetail {
                        Text(detail)
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .fill(
                                friend.currentStreak > 0
                                ? LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [ColorTheme.separator(colorScheme), ColorTheme.separator(colorScheme)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 40, height: 40)

                        VStack(spacing: -2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(friend.currentStreak)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.3))
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme).opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(FriendCardButtonStyle())
    }

    private var friendDetail: String? {
        let parts = [friend.team, friend.position].compactMap { $0?.isEmpty == false ? $0 : nil }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

private struct FriendCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Ring Avatar

struct RingAvatar: View {
    let name: String?
    let photoUrl: String?
    let size: CGFloat
    let colorScheme: ColorScheme

    init(name: String?, photoUrl: String? = nil, size: CGFloat, colorScheme: ColorScheme) {
        self.name = name
        self.photoUrl = photoUrl
        self.size = size
        self.colorScheme = colorScheme
    }

    var body: some View {
        let initial = name?.first.map(String.init) ?? "?"
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "358A90"), ColorTheme.accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: size + 6, height: size + 6)

            if let photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        initialsCircle(initial)
                    }
                }
            } else {
                initialsCircle(initial)
            }
        }
    }

    private func initialsCircle(_ initial: String) -> some View {
        Text(initial.uppercased())
            .font(.system(size: size * 0.38, weight: .bold).width(.condensed))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [ColorTheme.accent, Color(hex: "2A7A80")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}
