import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var subscriptionShimmer: CGFloat = -1
    @State private var showAccountUpgrade = false
    @State private var showFeedback = false
    @State private var showBugReport = false
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
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
                    VStack(spacing: 24) {
                        profileHeader
                            .opacity(headerAppeared ? 1 : 0)
                            .offset(y: headerAppeared ? 0 : 20)

                        if isGuest {
                            guestAccountSection
                        }

                        streakCards
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 16)

                        mantraCard
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 16)

                        premiumCard
                            .opacity(cardsAppeared ? 1 : 0)

                        contactUsCard
                            .opacity(cardsAppeared ? 1 : 0)

                        feedbackCard
                            .opacity(cardsAppeared ? 1 : 0)

                        bugReportCard
                            .opacity(cardsAppeared ? 1 : 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                await viewModel.loadData()
                withAnimation(.easeOut(duration: 0.5)) {
                    headerAppeared = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    cardsAppeared = true
                }
            }
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
            .sheet(isPresented: $viewModel.showEditProfile) {
                EditProfileSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
            }
            .sheet(isPresented: $showBugReport) {
                BugReportView()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.08))
                    .frame(width: 130, height: 130)

                Circle()
                    .fill(ColorTheme.accent.opacity(0.04))
                    .frame(width: 150, height: 150)

                if let image = viewModel.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ColorTheme.accent.opacity(0.25), ColorTheme.accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Text(initialsText)
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(ColorTheme.accent)
                }

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [ColorTheme.accent, Color(hex: "358A90"), ColorTheme.accent.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 106, height: 106)

                if viewModel.isPremium {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 28, height: 28)
                                    .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 6, x: 0, y: 2)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -2, y: -2)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }

            VStack(spacing: 6) {
                if let name = viewModel.user?.fullName, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 24, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                if let username = viewModel.user?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }

            infoBadges

            Button {
                HapticManager.impact(.light)
                viewModel.showEditProfile = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                    Text("Edit Profile")
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                }
                .foregroundColor(ColorTheme.accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(ColorTheme.accent.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(ColorTheme.accent.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [ColorTheme.accent.opacity(0.04), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: ColorTheme.accent.opacity(0.06), radius: 20, x: 0, y: 8)
    }

    private var infoBadges: some View {
        HStack(spacing: 8) {
            if let sport = viewModel.user?.sport {
                infoBadge(icon: sportIcon(sport), text: sport.capitalized, color: sportColor(sport))
            }
            if let position = viewModel.user?.position, !position.isEmpty {
                infoBadge(icon: "person.fill", text: position, color: Color(hex: "8B5CF6"))
            }
            if let team = viewModel.user?.team, !team.isEmpty {
                infoBadge(icon: "shield.fill", text: team, color: Color(hex: "3B82F6"))
            }
        }
    }

    private func infoBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
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

    private func sportColor(_ sport: String) -> Color {
        switch sport.lowercased() {
        case "soccer": return Color(hex: "22C55E")
        case "basketball": return Color(hex: "F97316")
        case "tennis": return Color(hex: "EAB308")
        case "football": return Color(hex: "8B4513")
        case "boxing": return Color(hex: "EF4444")
        case "cricket": return Color(hex: "3B82F6")
        default: return ColorTheme.accent
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "F59E0B").opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streak Cards

    private var streakCards: some View {
        HStack(spacing: 12) {
            streakCard(
                value: viewModel.streak?.currentStreak ?? 0,
                label: "Current Streak",
                icon: "flame.fill",
                gradient: [Color(hex: "F97316"), Color(hex: "EF4444")],
                glowColor: Color(hex: "F97316")
            )
            streakCard(
                value: viewModel.streak?.longestStreak ?? 0,
                label: "Best Streak",
                icon: "trophy.fill",
                gradient: [Color(hex: "EAB308"), Color(hex: "F59E0B")],
                glowColor: Color(hex: "EAB308")
            )
        }
    }

    private func streakCard(value: Int, label: String, icon: String, gradient: [Color], glowColor: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: glowColor.opacity(0.35), radius: 10, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("\(value)")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .contentTransition(.numericText())

            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [glowColor.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(glowColor.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Mantra Card

    private var mantraCard: some View {
        Group {
            if let mantra = viewModel.user?.mantra, !mantra.isEmpty {
                Button {
                    viewModel.showMantraEditor = true
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ColorTheme.accent)
                            Text("YOUR MANTRA")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(ColorTheme.accent)
                                .tracking(1)
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        }

                        Text("\u{201C}\(mantra)\u{201D}")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .italic()
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(
                        ZStack {
                            ColorTheme.cardBackground(colorScheme)
                            LinearGradient(
                                colors: [ColorTheme.accent.opacity(0.06), .clear, ColorTheme.accent.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(ColorTheme.accent.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: ColorTheme.accent.opacity(0.06), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    viewModel.showMantraEditor = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(ColorTheme.subtleAccent(colorScheme))
                                .frame(width: 40, height: 40)
                            Image(systemName: "quote.opening")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(ColorTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Your Mantra")
                                .font(.system(size: 15, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Text("A personal phrase to keep you focused")
                                .font(.system(size: 12, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(ColorTheme.accent)
                    }
                    .padding(16)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
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
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .shadow(color: Color(hex: "FFD700").opacity(0.3), radius: 8, x: 0, y: 3)
                Image(systemName: "crown.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Premium Active")
                    .font(.system(size: 16, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("AI coaching reports unlocked")
                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                    .foregroundColor(Color(hex: "FFD700"))
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "22C55E"))
        }
        .padding(16)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [Color(hex: "FFD700").opacity(0.06), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(hex: "FFD700").opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color(hex: "FFD700").opacity(0.08), radius: 10, x: 0, y: 4)
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
                        .frame(width: 42, height: 42)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
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
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "7C3AED").opacity(0.25), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                subscriptionShimmer = 2
            }
        }
    }

    // MARK: - Contact Us Card

    private var contactUsCard: some View {
        Button {
            HapticManager.selection()
            if let url = URL(string: "mailto:contact@alsancar.co.uk") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "3B82F6").opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "3B82F6"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Contact Us")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("contact@alsancar.co.uk")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feedback Card

    private var feedbackCard: some View {
        Button {
            HapticManager.selection()
            showFeedback = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "F59E0B").opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Feedback & Suggestions")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Help us improve I Can")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bug Report Card

    private var bugReportCard: some View {
        Button {
            HapticManager.selection()
            showBugReport = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "EF4444").opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "EF4444"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Report a Bug")
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Let us know if something is broken")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

}
