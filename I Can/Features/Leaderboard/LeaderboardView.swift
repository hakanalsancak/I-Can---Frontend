import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                tabPicker
                content
                myPositionCard
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.loadAll() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .frame(width: 34, height: 34)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "EAB308"))
                    Text("RANKINGS")
                        .font(.system(size: 16, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                Spacer()

                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Global", icon: "globe", index: 0)
            tabButton(title: countryName, icon: nil, flagEmoji: countryFlag, index: 1)
        }
        .padding(4)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func tabButton(title: String, icon: String?, flagEmoji: String? = nil, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
            HapticManager.selection()
        } label: {
            HStack(spacing: 5) {
                if let flag = flagEmoji {
                    Text(flag)
                        .font(.system(size: 16))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .heavy).width(.condensed))
            }
            .foregroundColor(selectedTab == index ? .white : ColorTheme.secondaryText(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selectedTab == index
                    ? AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "EAB308"), Color(hex: "F59E0B")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if selectedTab == 0 {
                leaderboardList(
                    entries: viewModel.globalEntries,
                    isLoading: viewModel.isLoadingGlobal
                )
            } else {
                leaderboardList(
                    entries: viewModel.countryEntries,
                    isLoading: viewModel.isLoadingCountry
                )
            }
        }
    }

    private func leaderboardList(entries: [LeaderboardEntry], isLoading: Bool) -> some View {
        ScrollView(showsIndicators: false) {
            if isLoading {
                VStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in
                        loadingRow
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            } else if entries.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    if entries.count >= 3 {
                        podiumView(entries: Array(entries.prefix(3)))
                            .padding(.bottom, 16)
                    }

                    let startIndex = min(3, entries.count)
                    ForEach(Array(entries.dropFirst(startIndex).enumerated()), id: \.element.userId) { _, entry in
                        leaderboardRow(entry: entry)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Podium

    private func podiumView(entries: [LeaderboardEntry]) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if entries.count > 1 {
                podiumCard(entry: entries[1], topPad: 16, medal: "2")
            }
            if entries.count > 0 {
                podiumCard(entry: entries[0], topPad: 40, medal: "1")
            }
            if entries.count > 2 {
                podiumCard(entry: entries[2], topPad: 0, medal: "3")
            }
        }
        .padding(.top, 8)
    }

    private func podiumCard(entry: LeaderboardEntry, topPad: CGFloat, medal: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(medalGradient(medal))
                    .frame(width: 40, height: 40)
                    .shadow(color: medalColor(medal).opacity(0.4), radius: 8, x: 0, y: 4)

                Text(medal)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(displayName(entry.fullName))
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineLimit(1)

            Text(sportIcon(entry.sport))
                .font(.system(size: 14))

            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "F97316"))
                Text("\(entry.currentStreak)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }

            if let country = entry.country {
                Text(flagEmoji(for: country))
                    .font(.system(size: 13))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, topPad + 10)
        .padding(.bottom, 10)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                medalColor(medal).opacity(0.06)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(medalColor(medal).opacity(0.2), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Row

    private func leaderboardRow(entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(entry.isMe ? Color(hex: "EAB308") : ColorTheme.secondaryText(colorScheme))
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(entry.fullName))
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(entry.isMe ? Color(hex: "EAB308") : ColorTheme.primaryText(colorScheme))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(sportIcon(entry.sport))
                        .font(.system(size: 12))
                    if let country = entry.country {
                        Text(flagEmoji(for: country))
                            .font(.system(size: 12))
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "F97316"))
                Text("\(entry.currentStreak)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            entry.isMe
                ? Color(hex: "EAB308").opacity(0.08)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            Group {
                if entry.isMe {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(hex: "EAB308").opacity(0.2), lineWidth: 1)
                }
            }
        )
    }

    // MARK: - My Position

    private var myPositionCard: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("YOUR RANK")
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    let rank = selectedTab == 0 ? viewModel.myGlobalRank : viewModel.myCountryRank
                    Text(rank != nil ? "#\(rank!)" : "--")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "EAB308"))
                }

                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(width: 1, height: 32)

                VStack(spacing: 2) {
                    Text("YOUR STREAK")
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "F97316"))
                        Text("\(viewModel.myStreak)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(selectedTab == 0 ? "GLOBAL" : countryName.uppercased())
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text(selectedTab == 0 ? "🌍" : countryFlag)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(ColorTheme.cardBackground(colorScheme))
        }
    }

    // MARK: - Empty / Loading

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Text("No athletes ranked yet")
                .font(.system(size: 16, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text("Start logging your performance to climb the rankings!")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private var loadingRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(ColorTheme.tertiaryText(colorScheme).opacity(0.3))
                .frame(width: 36, height: 20)
            RoundedRectangle(cornerRadius: 6)
                .fill(ColorTheme.tertiaryText(colorScheme).opacity(0.3))
                .frame(height: 20)
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(ColorTheme.tertiaryText(colorScheme).opacity(0.3))
                .frame(width: 40, height: 20)
        }
        .padding(.vertical, 12)
        .shimmer()
    }

    // MARK: - Helpers

    private func displayName(_ name: String) -> String {
        let parts = name.components(separatedBy: " ")
        guard let first = parts.first, !first.isEmpty else { return "Athlete" }
        if parts.count > 1, let lastInitial = parts.last?.first {
            return "\(first) \(lastInitial)."
        }
        return first
    }

    private func sportIcon(_ sport: String) -> String {
        switch sport {
        case "soccer": return "⚽"
        case "basketball": return "🏀"
        case "tennis": return "🎾"
        case "football": return "🏈"
        case "boxing": return "🥊"
        case "cricket": return "🏏"
        default: return "🏅"
        }
    }

    private var countryFlag: String {
        flagEmoji(for: viewModel.userCountryCode)
    }

    private var countryName: String {
        Locale.current.localizedString(forRegionCode: viewModel.userCountryCode) ?? viewModel.userCountryCode
    }

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        return code.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value).map(String.init)
        }.joined()
    }

    private func medalColor(_ medal: String) -> Color {
        switch medal {
        case "1": return Color(hex: "EAB308")
        case "2": return Color(hex: "94A3B8")
        case "3": return Color(hex: "CD7F32")
        default: return ColorTheme.accent
        }
    }

    private func medalGradient(_ medal: String) -> LinearGradient {
        switch medal {
        case "1":
            return LinearGradient(colors: [Color(hex: "EAB308"), Color(hex: "F59E0B")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case "2":
            return LinearGradient(colors: [Color(hex: "94A3B8"), Color(hex: "CBD5E1")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case "3":
            return LinearGradient(colors: [Color(hex: "CD7F32"), Color(hex: "B8860B")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [ColorTheme.accent], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Shimmer Modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
