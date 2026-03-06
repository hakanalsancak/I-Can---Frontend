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
        VStack(spacing: 16) {
            HStack {
                Label(entry.activityTypeDisplay, systemImage: entry.activityIcon)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                PerformanceScoreCard(score: entry.performanceScore)
            }
            .cardStyle(colorScheme)

            HStack(spacing: 16) {
                ratingCard(label: "Focus", value: entry.focusRating)
                ratingCard(label: "Effort", value: entry.effortRating)
                ratingCard(label: "Confidence", value: entry.confidenceRating)
            }

            if let didWell = entry.didWell, !didWell.isEmpty {
                reflectionCard(title: "Did Well", icon: "hand.thumbsup", text: didWell)
            }

            if let improve = entry.improveNext, !improve.isEmpty {
                reflectionCard(title: "Improve Next", icon: "arrow.up.circle", text: improve)
            }

            if let qId = entry.rotatingQuestionId, let answer = entry.rotatingAnswer {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rotatingQuestions[qId] ?? "Daily Question")
                            .font(Typography.footnote)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        Text(answer)
                            .font(Typography.body)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func ratingCard(label: String, value: Int) -> some View {
        CardView {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(Typography.title2)
                    .foregroundColor(ColorTheme.accent)
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func reflectionCard(title: String, icon: String, text: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text(text)
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
