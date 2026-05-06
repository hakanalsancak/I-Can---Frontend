import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var selectedProfile: AthleteProfile?
    @State private var showBlocked = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Friends") {
                    Button {
                        showBlocked = true
                    } label: {
                        Image(systemName: "hand.raised.slash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                FriendsListContent(viewModel: viewModel) { profile in
                    selectedProfile = profile
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { Task { await viewModel.loadAll() } }
            .sheet(isPresented: $showBlocked) {
                BlockedUsersView()
            }
            .sheet(item: $selectedProfile) { profile in
                AthleteProfileSheet(athleteId: profile.id) {
                    Task { await viewModel.removeFriend(profile) }
                }
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
