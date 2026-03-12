import SwiftUI

struct GameStatsView: View {
    let sport: String
    @Binding var stats: [String: Int]
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var statFields: [(key: String, label: String, icon: String)] {
        switch sport {
        case "soccer":
            return [
                ("goals", "Goals scored", "sportscourt.fill"),
                ("assists", "Assists", "arrow.right.arrow.left"),
                ("shotsOnTarget", "Shots on target", "scope"),
                ("keyPasses", "Key passes", "arrow.up.forward"),
                ("tackles", "Tackles / interceptions", "shield.fill"),
            ]
        case "basketball":
            return [
                ("points", "Points scored", "basketball.fill"),
                ("assists", "Assists", "arrow.right.arrow.left"),
                ("rebounds", "Rebounds", "arrow.up.circle"),
                ("steals", "Steals", "hand.raised.fill"),
                ("turnovers", "Turnovers", "arrow.uturn.left"),
            ]
        case "tennis":
            return [
                ("setsWon", "Sets won", "checkmark.circle"),
                ("setsLost", "Sets lost", "xmark.circle"),
                ("aces", "Aces", "bolt.fill"),
                ("doubleFaults", "Double faults", "exclamationmark.triangle"),
                ("winners", "Winners", "star.fill"),
                ("unforcedErrors", "Unforced errors", "arrow.down.circle"),
            ]
        case "football":
            return [
                ("touchdowns", "Touchdowns", "football.fill"),
                ("yardsGained", "Yards gained", "arrow.right"),
                ("passCompletions", "Pass completions", "checkmark.circle"),
                ("receptions", "Receptions", "hand.raised.fill"),
                ("tackles", "Tackles", "shield.fill"),
                ("sacks", "Sacks", "bolt.fill"),
                ("interceptions", "Interceptions", "arrow.uturn.left"),
            ]
        case "cricket":
            return [
                ("runsScored", "Runs scored", "figure.cricket"),
                ("ballsFaced", "Balls faced", "circle.fill"),
                ("wicketsTaken", "Wickets taken", "flame.fill"),
                ("catches", "Catches", "hand.raised.fill"),
            ]
        case "boxing":
            return [
                ("roundsFought", "Rounds fought", "figure.boxing"),
                ("cleanPunches", "Clean punches landed", "bolt.fill"),
                ("knockdowns", "Knockdowns", "arrow.down.circle"),
                ("warnings", "Warnings / penalties", "exclamationmark.triangle"),
            ]
        default:
            return [
                ("points", "Points / score", "star.fill"),
                ("assists", "Assists", "arrow.right.arrow.left"),
            ]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Game Stats")
                            .font(.system(size: 26, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("Enter your numbers")
                            .font(.system(size: 14, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    VStack(spacing: 10) {
                        ForEach(statFields, id: \.key) { field in
                            StatInputRow(
                                label: field.label,
                                icon: field.icon,
                                value: Binding(
                                    get: { stats[field.key] ?? 0 },
                                    set: { stats[field.key] = $0 }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }

            HStack(spacing: 12) {
                Button {
                    HapticManager.impact(.light)
                    withAnimation { onBack() }
                } label: {
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(width: 100)

                PrimaryButton(title: "Continue") {
                    HapticManager.impact(.medium)
                    withAnimation { onNext() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Stat Input Row

private struct StatInputRow: View {
    let label: String
    let icon: String
    @Binding var value: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorTheme.accent)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 15, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value > 0 { value -= 1 }
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(value > 0 ? ColorTheme.primaryText(colorScheme) : ColorTheme.tertiaryText(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .frame(width: 44)
                    .contentTransition(.numericText())

                Button {
                    value += 1
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
    }
}
