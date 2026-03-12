import SwiftUI

struct AthleteProfileSheet: View {
    let athleteId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var profile: AthleteProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(ColorTheme.accent)
                } else if let profile {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            profileHeader(profile)
                            statsRow(profile)
                            detailsSection(profile)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 36))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        Text(error)
                            .font(Typography.body)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .task { await loadProfile() }
        }
    }

    private func profileHeader(_ p: AthleteProfile) -> some View {
        VStack(spacing: 14) {
            Text(String((p.fullName ?? "?").prefix(1)).uppercased())
                .font(.system(size: 36, weight: .bold).width(.condensed))
                .foregroundColor(.white)
                .frame(width: 90, height: 90)
                .background(
                    LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "358A90")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: ColorTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)

            VStack(spacing: 4) {
                Text(p.fullName ?? "Athlete")
                    .font(.system(size: 24, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let username = p.username {
                    Text("@\(username)")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }

            if let team = p.team, !team.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                        .font(.system(size: 13))
                    Text(team)
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                }
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            HStack(spacing: 16) {
                if let position = p.position, !position.isEmpty {
                    detailPill(icon: "person.fill", text: position)
                }
                if let sport = p.sport, !sport.isEmpty {
                    detailPill(icon: "sportscourt", text: sport.capitalized)
                }
                if let country = p.country, !country.isEmpty {
                    detailPill(icon: "globe", text: country)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func detailPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12, weight: .semibold).width(.condensed))
        }
        .foregroundColor(ColorTheme.secondaryText(colorScheme))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(Capsule())
    }

    private func statsRow(_ p: AthleteProfile) -> some View {
        HStack(spacing: 16) {
            statCard(value: "\(p.currentStreak)", label: "Current Streak", icon: "flame.fill", iconColor: .orange)
            statCard(value: "\(p.longestStreak ?? 0)", label: "Best Streak", icon: "trophy.fill", iconColor: .yellow)
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text(label)
                .font(.system(size: 12, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    private func detailsSection(_ p: AthleteProfile) -> some View {
        VStack(spacing: 12) {
            if let level = p.competitionLevel, !level.isEmpty {
                detailRow(icon: "chart.bar.fill", label: "Level", value: formatLevel(level))
            }
            if let mantra = p.mantra, !mantra.isEmpty {
                detailRow(icon: "quote.opening", label: "Mantra", value: "\"\(mantra)\"")
            }
        }
        .padding(.horizontal, 20)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ColorTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text(value)
                    .font(.system(size: 15, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }

            Spacer()
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    private func formatLevel(_ level: String) -> String {
        switch level {
        case "beginner": return "Beginner"
        case "amateur": return "Amateur"
        case "semi_pro": return "Semi-Pro"
        case "professional": return "Professional"
        case "elite": return "Elite / International"
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
