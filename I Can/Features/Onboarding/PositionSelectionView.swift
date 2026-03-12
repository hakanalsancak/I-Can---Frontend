import SwiftUI

struct PositionSelectionView: View {
    @Binding var position: String
    let sport: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var positions: [String] {
        switch sport {
        case "soccer":
            return ["Goalkeeper", "Centre-Back", "Full-Back", "Defensive Midfielder", "Central Midfielder", "Attacking Midfielder", "Winger", "Striker"]
        case "basketball":
            return ["Point Guard", "Shooting Guard", "Small Forward", "Power Forward", "Center"]
        case "tennis":
            return ["Singles", "Doubles", "Both"]
        case "football":
            return ["Quarterback", "Running Back", "Wide Receiver", "Tight End", "Offensive Line", "Defensive Line", "Linebacker", "Cornerback", "Safety", "Kicker / Punter"]
        case "boxing":
            return ["Heavyweight", "Light Heavyweight", "Middleweight", "Welterweight", "Lightweight", "Featherweight", "Bantamweight", "Flyweight"]
        case "cricket":
            return ["Batsman", "Bowler (Pace)", "Bowler (Spin)", "All-Rounder", "Wicket-Keeper"]
        default:
            return ["Player"]
        }
    }

    private var title: String {
        switch sport {
        case "boxing": return "Weight Class"
        case "tennis": return "Play Style"
        default: return "Your Position"
        }
    }

    private var subtitle: String {
        switch sport {
        case "boxing": return "Select your weight class"
        case "tennis": return "What do you mainly play?"
        default: return "What position do you play?"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ], spacing: 10) {
                    ForEach(positions, id: \.self) { pos in
                        Button {
                            HapticManager.impact(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                position = pos
                            }
                        } label: {
                            Text(pos)
                                .font(.system(size: 15, weight: .semibold).width(.condensed))
                                .foregroundColor(position == pos ? .white : ColorTheme.primaryText(colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    position == pos
                                    ? ColorTheme.accent
                                    : ColorTheme.cardBackground(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            position == pos ? ColorTheme.accent : ColorTheme.separator(colorScheme),
                                            lineWidth: position == pos ? 2 : 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 0) {
                Divider().opacity(0.3)
                HStack(spacing: 12) {
                    Button {
                        withAnimation { onBack() }
                    } label: {
                        Text("Back")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }

                    PrimaryButton(
                        title: "Continue",
                        isDisabled: position.isEmpty
                    ) {
                        withAnimation { onNext() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
    }
}
