import SwiftUI

struct GoalCard: View {
    let goal: Goal
    let isJustCompleted: Bool
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var typeColor: Color {
        switch goal.goalType {
        case "weekly": return Color(hex: "3B82F6")
        case "monthly": return Color(hex: "8B5CF6")
        case "yearly": return Color(hex: "F97316")
        default: return ColorTheme.accent
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: {
                HapticManager.impact(.light)
                onToggle()
            }) {
                ZStack {
                    if goal.isCompleted || isJustCompleted {
                        Circle()
                            .fill(Color(hex: "22C55E"))
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(ColorTheme.tertiaryText(colorScheme), lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }
                }
                .scaleEffect(isJustCompleted ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isJustCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: goal.goalTypeIcon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(typeColor)
                    Text(goal.goalTypeDisplay.uppercased())
                        .font(.system(size: 9, weight: .heavy).width(.condensed))
                        .foregroundColor(typeColor)
                }

                Text(goal.title)
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(
                        goal.isCompleted
                        ? ColorTheme.secondaryText(colorScheme)
                        : ColorTheme.primaryText(colorScheme)
                    )
                    .strikethrough(goal.isCompleted, color: ColorTheme.tertiaryText(colorScheme))

                if let desc = goal.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ColorTheme.cardBackground(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isJustCompleted
                    ? Color(hex: "22C55E").opacity(0.4)
                    : ColorTheme.separator(colorScheme),
                    lineWidth: isJustCompleted ? 2 : 1
                )
        )
        .shadow(
            color: isJustCompleted
            ? Color(hex: "22C55E").opacity(0.15)
            : ColorTheme.cardShadow(colorScheme),
            radius: isJustCompleted ? 12 : 8,
            x: 0, y: isJustCompleted ? 4 : 2
        )
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Goal", systemImage: "trash")
            }
        }
    }
}
