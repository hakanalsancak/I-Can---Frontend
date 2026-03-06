import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsSection
                    subscriptionCard
                    menuSection
                    signOutButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Profile")
            .task { await viewModel.loadData() }
            .sheet(isPresented: $viewModel.showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
        }
    }

    private var profileHeader: some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(ColorTheme.accent)

                if let name = viewModel.user?.fullName, !name.isEmpty {
                    Text(name)
                        .font(Typography.title2)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                if let email = viewModel.user?.email {
                    Text(email)
                        .font(Typography.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                if let sport = viewModel.user?.sport {
                    HStack(spacing: 4) {
                        Image(systemName: "sportscourt")
                        Text(sport.capitalized)
                    }
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(ColorTheme.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(viewModel.streak?.currentStreak ?? 0)",
                label: "Current Streak",
                icon: "flame.fill"
            )
            statCard(
                value: "\(viewModel.streak?.longestStreak ?? 0)",
                label: "Best Streak",
                icon: "trophy.fill"
            )
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        CardView {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(ColorTheme.accent)
                Text(value)
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var subscriptionCard: some View {
        Button {
            viewModel.showSubscription = true
        } label: {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isPremium ? "crown.fill" : "lock.fill")
                                .foregroundColor(viewModel.isPremium ? .yellow : ColorTheme.secondaryText(colorScheme))
                            Text(viewModel.isPremium ? "Premium Active" : "Upgrade to Premium")
                                .font(Typography.headline)
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        }
                        Text(viewModel.isPremium
                             ? "AI coaching reports unlocked"
                             : "Unlock AI-powered coaching insights")
                            .font(Typography.caption)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
        }
    }

    private var menuSection: some View {
        VStack(spacing: 2) {
            menuRow(icon: "gearshape.fill", title: "Settings") {
                viewModel.showSettings = true
            }
            menuRow(icon: "chart.bar.fill", title: "AI Reports") {
                // Navigate to reports tab
            }
        }
    }

    private func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(ColorTheme.accent)
                    .frame(width: 24)
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var signOutButton: some View {
        Button {
            viewModel.signOut()
        } label: {
            Text("Sign Out")
                .font(Typography.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
}
