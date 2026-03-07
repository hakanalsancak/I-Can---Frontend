import SwiftUI

struct EntryDetailView: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme

    private let rotatingQuestions: [Int: String] = [
        1: "How focused were you during training today?",
        2: "Did you give maximum effort today?",
        3: "How confident did you feel today?",
        4: "How well did you handle mistakes today?",
        5: "How disciplined were you today?",
        6: "How was your energy level today?",
        7: "Did you follow your training plan today?",
        8: "What did you learn today?",
        9: "How prepared did you feel today?",
        10: "How satisfied are you with today's performance?",
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Label(entry.activityTypeDisplay, systemImage: entry.activityIcon)
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                PerformanceScoreCard(score: entry.performanceScore)
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)

            HStack(spacing: 10) {
                ratingCard(label: "Focus", value: entry.focusRating)
                ratingCard(label: "Effort", value: entry.effortRating)
                ratingCard(label: "Confidence", value: entry.confidenceRating)
            }

            if let didWell = entry.didWell, !didWell.isEmpty {
                reflectionCard(title: "Did Well", icon: "hand.thumbsup", text: didWell)
            }

            if let improve = entry.improveNext, !improve.isEmpty {
                reflectionCard(title: "Improve Next", icon: "arrow.up.right", text: improve)
            }

            if let qId = entry.rotatingQuestionId, let answer = entry.rotatingAnswer {
                VStack(alignment: .leading, spacing: 8) {
                    Text(rotatingQuestions[qId] ?? "Daily Question")
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text(answer)
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
            }
        }
    }

    private func ratingCard(label: String, value: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(Typography.number(22))
                .foregroundColor(ratingColor(value))
            Text(label)
                .font(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private func ratingColor(_ value: Int) -> Color {
        switch value {
        case 8...10: return Color(hex: "22C55E")
        case 5...7: return ColorTheme.accent
        default: return Color(hex: "F97316")
        }
    }

    private func reflectionCard(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text(text)
                .font(Typography.body)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
