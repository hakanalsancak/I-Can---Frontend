import SwiftUI

struct PrimaryGoalView: View {
    @Binding var goal: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let goals: [(id: String, title: String, icon: String)] = [
        ("improve_performance", "Improve My Performance", "chart.line.uptrend.xyaxis"),
        ("build_consistency", "Build Consistency & Discipline", "flame"),
        ("mental_strength", "Strengthen My Mental Game", "brain.head.profile"),
        ("recover_injury", "Recover From Injury", "bandage"),
        ("reach_next_level", "Reach the Next Level", "arrow.up.circle"),
        ("stay_motivated", "Stay Motivated & Focused", "bolt.heart"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("What's Your Main Goal?")
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("What do you want to achieve with I Can?")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                ForEach(goals, id: \.id) { item in
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            goal = item.id
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(goal == item.id ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))
                                .frame(width: 32)

                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            Spacer()

                            if goal == item.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            goal == item.id
                            ? ColorTheme.accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
                            : ColorTheme.cardBackground(colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    goal == item.id ? ColorTheme.accent : ColorTheme.separator(colorScheme),
                                    lineWidth: goal == item.id ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

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
                        isDisabled: goal.isEmpty
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
