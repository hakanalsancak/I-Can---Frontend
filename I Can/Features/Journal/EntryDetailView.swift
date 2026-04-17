import SwiftUI

struct EntryDetailView: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme

    private var r: EntryResponses? { entry.responses }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Label("Daily Log", systemImage: "doc.text.fill")
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                if let date = entry.date {
                    Text(date, style: .date)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)

            legacyFields

            universalReflections
        }
    }

    // MARK: - Legacy Fields (from v1 entries that predate daily log)

    @ViewBuilder
    private var legacyFields: some View {
        if let r {
            if let w = r.workedOn, !w.isEmpty {
                chipRow(title: "WORKED ON", chips: w)
            }
            if let skill = r.skillImproved, !skill.isEmpty {
                textCard(title: "Skill Improved", icon: "arrow.up.circle.fill", text: skill, color: Color(hex: "22C55E"))
            }
            if let drill = r.hardestDrill, !drill.isEmpty {
                textCard(title: "Hardest Drill", icon: "flame.fill", text: drill, color: Color(hex: "F97316"))
            }
            if let mistake = r.commonMistake, !mistake.isEmpty {
                textCard(title: "Common Mistake", icon: "exclamationmark.triangle.fill", text: mistake, color: Color(hex: "EF4444"))
            }
            if let focus = r.tomorrowFocus, !focus.isEmpty {
                textCard(title: "Tomorrow's Focus", icon: "scope", text: focus, color: Color(hex: "3B82F6"))
            }
            if let fl = r.focusLabel {
                labelPill(title: "Focus", label: fl, color: Color(hex: "3B82F6"))
            }
            if let el = r.effortLabel {
                labelPill(title: "Effort", label: el, color: Color(hex: "F97316"))
            }
            if let stats = r.gameStats, !stats.isEmpty {
                gameStatsGrid(stats)
            }
            if let best = r.bestMoment, !best.isEmpty {
                textCard(title: "Best Moment", icon: "star.fill", text: best, color: Color(hex: "F59E0B"))
            }
            if let bm = r.biggestMistake, !bm.isEmpty {
                textCard(title: "Biggest Mistake", icon: "exclamationmark.triangle.fill", text: bm, color: Color(hex: "EF4444"))
            }
            if let improve = r.improveNextGame, !improve.isEmpty {
                textCard(title: "Improve Next Game", icon: "arrow.up.right", text: improve, color: Color(hex: "3B82F6"))
            }
            if let strongest = r.strongestAreas, !strongest.isEmpty {
                chipRow(title: "STRONGEST", chips: strongest)
            }
            if let pgf = r.preGameFeeling {
                labelPill(title: "Pre-game", label: pgf, color: Color(hex: "8B5CF6"))
            }
            if let op = r.overallPerformance {
                labelPill(title: "Performance", label: op, color: Color(hex: "22C55E"))
            }
            if let activities = r.recoveryActivities, !activities.isEmpty {
                chipRow(title: "RECOVERY", chips: activities)
            } else if let a = r.restActivities, !a.isEmpty {
                chipRow(title: "ACTIVITIES", chips: a)
            }
            if let study = r.sportStudy, !study.isEmpty {
                textCard(title: "Sport Study", icon: "book.fill", text: study, color: Color(hex: "8B5CF6"))
            }
            if let rf = r.restTomorrowFocus, !rf.isEmpty {
                textCard(title: "Tomorrow's Focus", icon: "scope", text: rf, color: Color(hex: "3B82F6"))
            }
            if let rq = r.recoveryQuality {
                labelPill(title: "Recovery", label: rq, color: Color(hex: "3B82F6"))
            }
            if let d = r.discipline {
                labelPill(title: "Discipline", label: d, color: Color(hex: "22C55E"))
            }
        }
    }

    // MARK: - Universal Reflections

    @ViewBuilder
    private var universalReflections: some View {
        if let proud = r?.proudMoment, !proud.isEmpty {
            textCard(title: "Proudest moment", icon: "trophy.fill", text: proud, color: Color(hex: "F59E0B"))
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
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(sorted, id: \.key) { key, value in
                    VStack(spacing: 3) {
                        Text("\(value)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text(formatStatKey(key))
                            .font(.system(size: 9, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(14)
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

    // MARK: - Helpers

    private func labelPill(title: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text(label)
                .font(.system(size: 14, weight: .bold).width(.condensed))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func chipRow(title: String, chips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(chips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 12, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(ColorTheme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func textCard(title: String, icon: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(color)
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
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
