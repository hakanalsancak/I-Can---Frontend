import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    private var user: User? { AuthService.shared.currentUser }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("More")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile Summary Card
                        NavigationLink(destination: ProfileView()) {
                            profileCard
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                        // Navigation Items
                        VStack(spacing: 12) {
                            NavigationLink(destination: FriendsView()) {
                                navRow(
                                    icon: "person.2.fill",
                                    title: "Friends",
                                    subtitle: "Connect with athletes",
                                    gradient: [Color(hex: "0EA5E9"), Color(hex: "0284C7")]
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ProfileView()) {
                                navRow(
                                    icon: "person.crop.circle.fill",
                                    title: "Profile",
                                    subtitle: "Your stats & settings",
                                    gradient: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45).delay(0.05)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTheme.accent.opacity(0.25), ColorTheme.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text(initials)
                    .font(.system(size: 22, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user?.fullName ?? user?.username ?? "Athlete")
                    .font(.system(size: 18, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                HStack(spacing: 6) {
                    if let sport = user?.sport {
                        Text(sport)
                            .font(.system(size: 13, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ColorTheme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if SubscriptionService.shared.isPremium {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("PRO")
                                .font(.system(size: 11, weight: .heavy).width(.condensed))
                        }
                        .foregroundColor(Color(hex: "F59E0B"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(hex: "F59E0B").opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }

    // MARK: - Navigation Row

    private func navRow(icon: String, title: String, subtitle: String, gradient: [Color]) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: gradient[0].opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helpers

    private var initials: String {
        guard let name = user?.fullName ?? user?.username else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
