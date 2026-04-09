import SwiftUI

struct AthleteProfileSheet: View {
    let athleteId: String
    var onRemoveFriend: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var profile: AthleteProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var glowPhase: CGFloat = 0
    @State private var showRemoveConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(ColorTheme.accent)
                        .scaleEffect(1.2)
                } else if let profile {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            profileHeader(profile)
                            badgesRow(profile)
                            statsRow(profile)
                            detailsSection(profile)

                            if profile.isFriend == true, onRemoveFriend != nil {
                                removeFriendButton
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ColorTheme.cardBackground(colorScheme))
                                .frame(width: 80, height: 80)
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        Text(error)
                            .font(Typography.body)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 32, height: 32)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .task { await loadProfile() }
            .alert("Remove Friend", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    onRemoveFriend?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to remove \(profile?.fullName ?? "this friend") from your friends?")
            }
        }
    }

    // MARK: - Remove Friend Button

    private var removeFriendButton: some View {
        Button {
            HapticManager.impact(.medium)
            showRemoveConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.minus")
                    .font(.system(size: 15, weight: .semibold))
                Text("Remove Friend")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Profile Header

    private func profileHeader(_ p: AthleteProfile) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.08))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(ColorTheme.accent.opacity(0.04))
                    .frame(width: 170, height: 170)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [ColorTheme.accent, Color(hex: "358A90"), ColorTheme.accent.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 108, height: 108)

                if let photoUrl = p.profilePhotoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(color: ColorTheme.accent.opacity(0.4), radius: 16, x: 0, y: 6)
                        default:
                            profileInitials(p)
                        }
                    }
                } else {
                    profileInitials(p)
                }
            }

            VStack(spacing: 6) {
                Text(p.fullName ?? "Athlete")
                    .font(.system(size: 26, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let username = p.username {
                    Text("@\(username)")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }

            if let team = p.team, !team.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ColorTheme.accent)
                    Text(team)
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }

        }
        .padding(.horizontal, 20)
    }

    private func profileInitials(_ p: AthleteProfile) -> some View {
        Text(String((p.fullName ?? "?").prefix(1)).uppercased())
            .font(.system(size: 42, weight: .heavy).width(.condensed))
            .foregroundColor(.white)
            .frame(width: 100, height: 100)
            .background(
                LinearGradient(
                    colors: [ColorTheme.accent, Color(hex: "2A7A80")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
            .shadow(color: ColorTheme.accent.opacity(0.4), radius: 16, x: 0, y: 6)
    }

    // MARK: - Badges Row

    private func badgesRow(_ p: AthleteProfile) -> some View {
        let badges: [(icon: String, text: String, color: Color)] = {
            var arr: [(String, String, Color)] = []
            if let sport = p.sport, !sport.isEmpty {
                arr.append((sportIcon(sport), sport.capitalized, sportColor(sport)))
            }
            if let position = p.position, !position.isEmpty {
                arr.append(("person.fill", position, Color(hex: "8B5CF6")))
            }
            if let country = p.country, !country.isEmpty {
                arr.append(("globe", country, Color(hex: "3B82F6")))
            }
            if let level = p.competitionLevel, !level.isEmpty {
                arr.append(("chart.bar.fill", formatLevel(level), Color(hex: "F59E0B")))
            }
            return arr
        }()

        guard !badges.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(badges.indices, id: \.self) { i in
                        let badge = badges[i]
                        HStack(spacing: 6) {
                            Image(systemName: badge.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(badge.color)
                            Text(badge.text)
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            badge.color.opacity(colorScheme == .dark ? 0.12 : 0.08)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(badge.color.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        )
    }

    // MARK: - Stats Row

    private func statsRow(_ p: AthleteProfile) -> some View {
        HStack(spacing: 14) {
            streakCard(
                value: p.currentStreak,
                label: "Current Streak",
                icon: "flame.fill",
                iconColor: .orange,
                gradientColors: [.orange.opacity(0.15), .red.opacity(0.08)]
            )
            streakCard(
                value: p.longestStreak ?? 0,
                label: "Best Streak",
                icon: "trophy.fill",
                iconColor: .yellow,
                gradientColors: [.yellow.opacity(0.12), .orange.opacity(0.06)]
            )
        }
        .padding(.horizontal, 20)
    }

    private func streakCard(value: Int, label: String, icon: String, iconColor: Color, gradientColors: [Color]) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(iconColor)
                .shadow(color: iconColor.opacity(0.4), radius: 4, x: 0, y: 2)

            Text("\(value)")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .contentTransition(.numericText())

            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(iconColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }

    // MARK: - Details Section

    private func detailsSection(_ p: AthleteProfile) -> some View {
        VStack(spacing: 14) {
            if (p.height != nil && p.height! > 0) || (p.weight != nil && p.weight! > 0) {
                heightWeightCard(p)
            }
            if let mantra = p.mantra, !mantra.isEmpty {
                mantraCard(mantra)
            }
        }
        .padding(.horizontal, 20)
    }

    private func heightWeightCard(_ p: AthleteProfile) -> some View {
        let pref = UnitPreference.shared
        return HStack(spacing: 0) {
            if let height = p.height, height > 0 {
                VStack(spacing: 6) {
                    Image(systemName: "ruler")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "06B6D4"))

                    if pref.heightUnit == .cm {
                        Text("\(Int(height))")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("CM")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                            .tracking(0.8)
                    } else {
                        let fi = UnitPreference.cmToFeetInches(height)
                        Text("\(fi.feet)'\(fi.inches)\"")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("FT")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                            .tracking(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if p.height != nil && p.height! > 0 && p.weight != nil && p.weight! > 0 {
                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(width: 1, height: 60)
            }

            if let weight = p.weight, weight > 0 {
                VStack(spacing: 6) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "10B981"))

                    if pref.weightUnit == .kg {
                        Text("\(Int(weight))")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("KG")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                            .tracking(0.8)
                    } else {
                        Text("\(Int(UnitPreference.kgToLbs(weight)))")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("LBS")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                            .tracking(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 20)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [Color(hex: "06B6D4").opacity(0.04), Color(hex: "10B981").opacity(0.04)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(ColorTheme.separator(colorScheme).opacity(0.5), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }

    private func mantraCard(_ mantra: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(ColorTheme.accent.opacity(0.5))

            Text(mantra)
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .italic()
                .lineSpacing(4)

            Text("PERSONAL MANTRA")
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.5))
                .tracking(1.5)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [ColorTheme.accent.opacity(0.06), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: ColorTheme.accent.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func sportIcon(_ sport: String) -> String {
        switch sport.lowercased() {
        case "soccer": return "sportscourt.fill"
        case "basketball": return "basketball.fill"
        case "tennis": return "tennisball.fill"
        case "football": return "football.fill"
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

    private func formatLevel(_ level: String) -> String {
        switch level {
        case "beginner": return "Beginner"
        case "amateur": return "Amateur"
        case "semi_pro": return "Semi-Pro"
        case "professional": return "Professional"
        case "elite": return "Elite"
        default: return level.capitalized
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            profile = try await FriendService.shared.getFriendProfile(id: athleteId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
