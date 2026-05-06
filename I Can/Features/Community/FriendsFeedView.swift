import SwiftUI

struct FriendsFeedView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var selectedProfile: AthleteProfile?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
            FriendsListContent(viewModel: viewModel) { profile in
                selectedProfile = profile
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { Task { await viewModel.loadAll() } }
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
