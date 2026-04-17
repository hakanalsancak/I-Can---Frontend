import SwiftUI

struct TodayEntryDetailSheet: View {
    let entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var r: EntryResponses? { entry.responses }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard

                    legacyFields

                    universalReflections
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Today's Entry")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today's Reflection")
                .font(.system(size: 18, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            if let date = entry.date {
                Text(date, style: .date)
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    // MARK: - Legacy Fields (from v1 entries that predate daily log)

    @ViewBuilder
    private var legacyFields: some View {
        if let r {
            if let worked = r.workedOn, !worked.isEmpty {
                chipSection(title: "WORKED ON", chips: worked, color: ColorTheme.accent)
            }
            if let skill = r.skillImproved, !skill.isEmpty {
                reflectionCard(title: "Skill Improved", icon: "arrow.up.circle.fill", text: skill, color: Color(hex: "22C55E"))
            }
            if let drill = r.hardestDrill, !drill.isEmpty {
                reflectionCard(title: "Hardest Drill", icon: "flame.fill", text: drill, color: Color(hex: "F97316"))
            }
            if let mistake = r.commonMistake, !mistake.isEmpty {
                reflectionCard(title: "Common Mistake", icon: "exclamationmark.triangle.fill", text: mistake, color: Color(hex: "EF4444"))
            }
            if let focus = r.tomorrowFocus, !focus.isEmpty {
                reflectionCard(title: "Tomorrow's Focus", icon: "scope", text: focus, color: Color(hex: "3B82F6"))
            }
            if let stats = r.gameStats, !stats.isEmpty {
                gameStatsGrid(stats)
            }
            if let best = r.bestMoment, !best.isEmpty {
                reflectionCard(title: "Best Moment", icon: "star.fill", text: best, color: Color(hex: "F59E0B"))
            }
            if let bm = r.biggestMistake, !bm.isEmpty {
                reflectionCard(title: "Biggest Mistake", icon: "exclamationmark.triangle.fill", text: bm, color: Color(hex: "EF4444"))
            }
            if let improve = r.improveNextGame, !improve.isEmpty {
                reflectionCard(title: "Improve Next Game", icon: "arrow.up.right", text: improve, color: Color(hex: "3B82F6"))
            }
            if let activities = r.recoveryActivities, !activities.isEmpty {
                chipSection(title: "RECOVERY", chips: activities, color: ColorTheme.accent)
            }
            if let study = r.sportStudy, !study.isEmpty {
                reflectionCard(title: "Sport Study", icon: "book.fill", text: study, color: Color(hex: "8B5CF6"))
            }
            if let rf = r.restTomorrowFocus, !rf.isEmpty {
                reflectionCard(title: "Tomorrow's Focus", icon: "scope", text: rf, color: Color(hex: "3B82F6"))
            }
        }
    }

    // MARK: - Universal Reflections

    @ViewBuilder
    private var universalReflections: some View {
        if let proud = r?.proudMoment, !proud.isEmpty {
            reflectionCard(title: "Proudest moment", icon: "trophy.fill", text: proud, color: Color(hex: "F59E0B"))
        }
    }

    // MARK: - Game Stats Grid

    private func gameStatsGrid(_ stats: [String: Int]) -> some View {
        let sorted = stats.sorted { $0.key < $1.key }
        return VStack(alignment: .leading, spacing: 10) {
            Text("GAME STATS")
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(sorted, id: \.key) { key, value in
                    VStack(spacing: 4) {
                        Text("\(value)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text(formatStatKey(key))
                            .font(.system(size: 10, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func formatStatKey(_ key: String) -> String {
        let map: [String: String] = [
            "goals": "Goals", "assists": "Assists", "shotsOnTarget": "Shots on Target",
            "keyPasses": "Key Passes", "tackles": "Tackles",
            "points": "Points", "rebounds": "Rebounds", "steals": "Steals", "turnovers": "Turnovers",
            "setsWon": "Sets Won", "setsLost": "Sets Lost", "aces": "Aces",
            "doubleFaults": "Double Faults", "winners": "Winners", "unforcedErrors": "Unforced Errors",
            "touchdowns": "Touchdowns", "yardsGained": "Yards", "passCompletions": "Pass Comp.",
            "receptions": "Receptions", "sacks": "Sacks", "interceptions": "Interceptions",
            "runsScored": "Runs", "ballsFaced": "Balls Faced", "wicketsTaken": "Wickets", "catches": "Catches",
            "roundsFought": "Rounds", "cleanPunches": "Clean Punches",
            "knockdowns": "Knockdowns", "warnings": "Warnings"
        ]
        return map[key] ?? key.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized
    }

    // MARK: - Chip Section

    private func chipSection(title: String, chips: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            FlowLayout(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Reflection Card

    private func reflectionCard(title: String, icon: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .bold).width(.condensed))
                    .foregroundColor(color)
                    .textCase(.uppercase)
            }

            Text(text)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }
}
