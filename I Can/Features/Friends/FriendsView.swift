import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var selectedProfile: AthleteProfile?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
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
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadAll() }
            .refreshable { await viewModel.loadAll() }
            .sheet(item: $selectedProfile) { profile in
                AthleteProfileSheet(athleteId: profile.id)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .font(.system(size: 16, weight: .medium))

            TextField("Search by username or name...", text: $viewModel.searchText)
                .font(.system(size: 16, weight: .medium).width(.condensed))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: viewModel.searchText) { _, newValue in
                    viewModel.search(query: newValue)
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
        )
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(ColorTheme.accent)
                    Spacer()
                }
                .padding(.top, 40)
            } else if viewModel.searchResults.isEmpty && viewModel.searchText.count >= 2 {
                VStack(spacing: 8) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text("No athletes found")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                Text("RESULTS")
                    .font(.system(size: 12, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
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

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FRIEND REQUESTS")
                    .font(.system(size: 12, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                Text("\(viewModel.pendingRequests.count)")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
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

    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY FRIENDS")
                    .font(.system(size: 12, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                Spacer()

                Text("\(viewModel.friends.count)")
                    .font(.system(size: 13, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.horizontal, 20)

            if viewModel.isLoading && viewModel.friends.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(ColorTheme.accent)
                    Spacer()
                }
                .padding(.top, 40)
            } else if viewModel.friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.5))

                    Text("No friends yet")
                        .font(.system(size: 17, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Search for athletes by username or name\nto connect and track each other's progress")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
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
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let user: AthleteProfile
    let colorScheme: ColorScheme
    let onAdd: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            avatarView(name: user.fullName, size: 48, colorScheme: colorScheme)
                .onTapGesture { onTap() }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.fullName ?? "Athlete")
                    .font(.system(size: 16, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                if let team = user.team, !team.isEmpty {
                    Text(team)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.8))
                }
            }
            .onTapGesture { onTap() }

            Spacer()
                .onTapGesture { onTap() }

            friendStatusButton
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var friendStatusButton: some View {
        let status = user.friendStatus ?? "none"
        switch status {
        case "friends":
            Label("Friends", systemImage: "checkmark")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.green.opacity(0.12))
                .clipShape(Capsule())
        case "pending":
            Text("Pending")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ColorTheme.separator(colorScheme))
                .clipShape(Capsule())
        case "incoming":
            Text("Respond")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ColorTheme.accent.opacity(0.12))
                .clipShape(Capsule())
        default:
            Button {
                onAdd()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(ColorTheme.accent)
                .clipShape(Capsule())
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
        Button(action: onTap) {
            HStack(spacing: 14) {
                avatarView(name: request.sender.fullName, size: 48, colorScheme: colorScheme)

                VStack(alignment: .leading, spacing: 3) {
                    Text(request.sender.fullName ?? "Athlete")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    if let username = request.sender.username {
                        Text("@\(username)")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.accent)
                            .clipShape(Circle())
                    }

                    Button(action: onDecline) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1))
                    }
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ColorTheme.accent.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Friend Card

private struct FriendCard: View {
    let friend: AthleteProfile
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                avatarView(name: friend.fullName, size: 52, colorScheme: colorScheme)

                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.fullName ?? "Athlete")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    HStack(spacing: 6) {
                        if let username = friend.username {
                            Text("@\(username)")
                                .font(.system(size: 13, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                    }

                    if let team = friend.team, !team.isEmpty,
                       let position = friend.position, !position.isEmpty {
                        Text("\(team) · \(position)")
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.8))
                            .lineLimit(1)
                    } else if let team = friend.team, !team.isEmpty {
                        Text(team)
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.8))
                    } else if let position = friend.position, !position.isEmpty {
                        Text(position)
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.8))
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(friend.currentStreak)")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Avatar Helper

private func avatarView(name: String?, size: CGFloat, colorScheme: ColorScheme) -> some View {
    let initial = name?.first.map(String.init) ?? "?"
    return Text(initial.uppercased())
        .font(.system(size: size * 0.4, weight: .bold).width(.condensed))
        .foregroundColor(.white)
        .frame(width: size, height: size)
        .background(
            LinearGradient(
                colors: [ColorTheme.accent, Color(hex: "358A90")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
}
