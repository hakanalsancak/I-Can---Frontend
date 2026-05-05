import SwiftUI

struct BlockedUser: Identifiable, Codable, Hashable {
    let id: String
    let username: String?
    let fullName: String?
    let profilePhotoUrl: String?
    let sport: String?
    let blockedAt: String

    var displayName: String {
        if let n = fullName, !n.isEmpty { return n }
        if let u = username, !u.isEmpty { return u }
        return "Athlete"
    }
}

struct BlockedUsersView: View {
    @State private var users: [BlockedUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()
                content
            }
            .navigationTitle("Blocked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && users.isEmpty {
            ProgressView()
        } else if users.isEmpty {
            VStack(spacing: 6) {
                Spacer()
                Text("No one blocked.")
                    .font(.system(size: 16, weight: .semibold))
                Text("Blocked users won't see your profile or posts.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
        } else {
            List {
                ForEach(users) { user in
                    HStack(spacing: 12) {
                        avatar(user)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName)
                                .font(.system(size: 15, weight: .semibold))
                            if let s = user.sport {
                                Text(s.capitalized)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Unblock") {
                            Task { await unblock(user) }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ColorTheme.accent)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func avatar(_ user: BlockedUser) -> some View {
        if let s = user.profilePhotoUrl, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                if let image = phase.image { image.resizable().scaledToFill() }
                else { Circle().fill(Color.secondary.opacity(0.2)) }
            }
        } else {
            Circle().fill(ColorTheme.accent.opacity(0.18))
                .overlay(
                    Text(initials(user.displayName))
                        .font(.system(size: 13, weight: .semibold))
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

    private func load() async {
        struct Resp: Decodable { let items: [BlockedUser] }
        do {
            let r: Resp = try await APIClient.shared.request(APIEndpoints.Community.blocks)
            users = r.items
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.errorDescription
        }
        isLoading = false
    }

    private func unblock(_ user: BlockedUser) async {
        do {
            _ = try await ModerationService.shared.unblock(userId: user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            // silent
        }
    }
}
