import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var subscriptionShimmer: CGFloat = -1
    @State private var showAccountUpgrade = false
    @Environment(\.colorScheme) private var colorScheme

    private var isGuest: Bool {
        viewModel.user?.isGuest ?? false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Profile") {
                    Button {
                        HapticManager.selection()
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 34, height: 34)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        identityCard
                        if isGuest {
                            guestAccountSection
                        }
                        statsRow
                        mantraCard
                        premiumCard
                        menuSection
                        signOutRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.loadData() }
            .sheet(isPresented: $viewModel.showSubscription, onDismiss: {
                Task { try? await SubscriptionService.shared.checkStatus() }
            }) {
                SubscriptionView()
            }
            .sheet(isPresented: $viewModel.showMantraEditor) {
                MantraEditorSheet(
                    currentMantra: viewModel.user?.mantra ?? "",
                    onSave: { newMantra in
                        Task { await viewModel.saveMantra(newMantra) }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
                    .preferredColorScheme(AppearanceManager.shared.current.resolvedColorScheme)
            }
            .sheet(isPresented: $showAccountUpgrade) {
                AccountUpgradeSheet()
            }
        }
    }

    // MARK: - Guest Account Section

    private var guestAccountSection: some View {
        Button {
            HapticManager.impact(.medium)
            showAccountUpgrade = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F59E0B").opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sign In or Create Account")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Required to subscribe and restore purchases")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "F59E0B").opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Identity Card

    private var identityCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTheme.accent.opacity(0.2), ColorTheme.accent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Circle()
                    .strokeBorder(ColorTheme.accent.opacity(0.4), lineWidth: 2)
                    .frame(width: 64, height: 64)

                Text(initialsText)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let name = viewModel.user?.fullName, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 20, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                if let username = viewModel.user?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }

                if let email = viewModel.user?.email {
                    Text(email)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                if let sport = viewModel.user?.sport {
                    HStack(spacing: 4) {
                        Image(systemName: sportIcon(sport))
                            .font(.system(size: 10, weight: .bold))
                        Text(sport.capitalized)
                            .font(.system(size: 11, weight: .bold).width(.condensed))
                    }
                    .foregroundColor(ColorTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.accent.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var initialsText: String {
        guard let name = viewModel.user?.fullName, !name.isEmpty else { return "?" }
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func sportIcon(_ sport: String) -> String {
        switch sport.lowercased() {
        case "soccer", "football": return "sportscourt.fill"
        case "basketball": return "basketball.fill"
        case "tennis": return "tennis.racket"
        case "boxing": return "figure.boxing"
        case "cricket": return "cricket.ball.fill"
        default: return "figure.run"
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            streakStat(
                value: viewModel.streak?.currentStreak ?? 0,
                label: "Current streak",
                icon: "flame.fill",
                gradient: [Color(hex: "F97316"), Color(hex: "EF4444")]
            )
            streakStat(
                value: viewModel.streak?.longestStreak ?? 0,
                label: "Best streak",
                icon: "trophy.fill",
                gradient: [Color(hex: "EAB308"), Color(hex: "F59E0B")]
            )
        }
    }

    private func streakStat(value: Int, label: String, icon: String, gradient: [Color]) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text(label)
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Mantra Card

    private var mantraCard: some View {
        Group {
            if let mantra = viewModel.user?.mantra, !mantra.isEmpty {
                Button {
                    viewModel.showMantraEditor = true
                } label: {
                    VStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(ColorTheme.accent)
                            Text("YOUR MANTRA")
                                .font(.system(size: 11, weight: .heavy).width(.condensed))
                                .foregroundColor(ColorTheme.accent)
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        }

                        Text(mantra)
                            .font(.system(size: 18, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(
                        ZStack {
                            ColorTheme.cardBackground(colorScheme)
                            LinearGradient(
                                colors: [ColorTheme.accent.opacity(0.05), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ColorTheme.accent.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    viewModel.showMantraEditor = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.accent)
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.subtleAccent(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Your Mantra")
                                .font(.system(size: 14, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Text("A personal phrase to keep you focused")
                                .font(.system(size: 11, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorTheme.accent)
                    }
                    .padding(14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Premium Card

    private var premiumCard: some View {
        Group {
            if viewModel.isPremium {
                premiumActiveCard
            } else {
                premiumUpgradeCard
            }
        }
    }

    private var premiumActiveCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "22C55E").opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "22C55E"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Premium Active")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("AI coaching reports unlocked")
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(Color(hex: "22C55E"))
            }

            Spacer()

            Image(systemName: "crown.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "EAB308"))
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var premiumUpgradeCard: some View {
        Button {
            HapticManager.impact(.medium)
            viewModel.showSubscription = true
        } label: {
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
                        .frame(width: 40, height: 40)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text("1 month free trial")
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                    }
                    .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(14)
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
                                    colors: [.white.opacity(0), .white.opacity(0.1), .white.opacity(0)],
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
            .shadow(color: Color(hex: "7C3AED").opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                subscriptionShimmer = 2
            }
        }
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: 2) {
            menuRow(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Notifications, account",
                color: ColorTheme.secondaryText(colorScheme)
            ) {
                viewModel.showSettings = true
            }

        }
    }

    private func menuRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sign Out

    private var signOutRow: some View {
        Button {
            HapticManager.impact(.light)
            viewModel.signOut()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                Text("Sign Out")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
            }
            .foregroundColor(ColorTheme.secondaryText(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}
