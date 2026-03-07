import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var subscriptionShimmer: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Profile")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        profileHeader
                        statsRow
                        subscriptionCard

                        Text("GENERAL")
                            .sectionHeader(colorScheme)
                            .padding(.top, 4)

                        VStack(spacing: 2) {
                            menuRow(icon: "gearshape.fill", title: "Settings") {
                                viewModel.showSettings = true
                            }
                            menuRow(icon: "wind", title: "Mental Tools") {
                                viewModel.showMentalTools = true
                            }
                        }

                        signOutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.loadData() }
            .sheet(isPresented: $viewModel.showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $viewModel.showMentalTools) {
                NavigationStack {
                    MentalToolsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button { viewModel.showMentalTools = false } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                        .frame(width: 30, height: 30)
                                        .background(ColorTheme.elevatedBackground(colorScheme))
                                        .clipShape(Circle())
                                }
                            }
                        }
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ColorTheme.subtleAccent(colorScheme))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill")
                    .font(.system(size: 28).width(.condensed))
                    .foregroundStyle(ColorTheme.accentGradient)
            }

            VStack(spacing: 4) {
                if let name = viewModel.user?.fullName, !name.isEmpty {
                    Text(name)
                        .font(Typography.title2)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                if let email = viewModel.user?.email {
                    Text(email)
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }

            if let sport = viewModel.user?.sport {
                Text(sport.capitalized)
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(ColorTheme.subtleAccent(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(viewModel.streak?.currentStreak ?? 0)",
                label: "Current",
                icon: "flame.fill",
                iconColor: Color(hex: "F97316")
            )
            statCard(
                value: "\(viewModel.streak?.longestStreak ?? 0)",
                label: "Best",
                icon: "trophy.fill",
                iconColor: Color(hex: "EAB308")
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18).width(.condensed))
                .foregroundColor(iconColor)
            Text(value)
                .font(Typography.number(24))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text(label)
                .font(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var subscriptionCard: some View {
        Button {
            viewModel.showSubscription = true
        } label: {
            if viewModel.isPremium {
                HStack(spacing: 14) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18).width(.condensed))
                        .foregroundColor(Color(hex: "EAB308"))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "EAB308").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium Active")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("AI coaching reports unlocked")
                            .font(Typography.footnote)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
                .padding(14)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
            } else {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                            Text("1 month free trial")
                                .font(Typography.footnote)
                        }
                        .foregroundColor(.white.opacity(0.75))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        GeometryReader { geo in
                            let w = geo.size.width
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: w * 0.5)
                                .offset(x: subscriptionShimmer * w)
                                .blur(radius: 4)
                        }
                        .clipped()
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(hex: "7C3AED").opacity(0.35), radius: 12, x: 0, y: 6)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if !viewModel.isPremium {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    subscriptionShimmer = 2
                }
            }
        }
    }

    private func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
                    .frame(width: 24)
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var signOutButton: some View {
        Button {
            HapticManager.impact(.medium)
            viewModel.signOut()
        } label: {
            Text("Sign Out")
                .font(Typography.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.top, 8)
    }
}
