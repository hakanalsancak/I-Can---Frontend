import SwiftUI

struct TodayEntryDetailSheet: View {
    let entry: DailyEntry
    var onEdit: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
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
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard
                    ratingsRow
                    
                    if let didWell = entry.didWell, !didWell.isEmpty {
                        reflectionCard(
                            title: "What went well",
                            icon: "hand.thumbsup.fill",
                            text: didWell,
                            color: Color(hex: "22C55E")
                        )
                    }

                    if let improve = entry.improveNext, !improve.isEmpty {
                        reflectionCard(
                            title: "What to improve",
                            icon: "arrow.up.right",
                            text: improve,
                            color: Color(hex: "F97316")
                        )
                    }

                    if let qId = entry.rotatingQuestionId, let answer = entry.rotatingAnswer {
                        reflectionCard(
                            title: rotatingQuestions[qId] ?? "Daily Question",
                            icon: "questionmark.circle.fill",
                            text: answer,
                            color: Color(hex: "8B5CF6")
                        )
                    }
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onEdit?()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Edit")
                                .font(.system(size: 15, weight: .semibold).width(.condensed))
                        }
                        .foregroundColor(ColorTheme.accent)
                    }
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
        HStack(spacing: 16) {
            scoreRing

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.activityTypeDisplay)
                    .font(.system(size: 13, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
                    .textCase(.uppercase)

                Text("Performance Score")
                    .font(.system(size: 18, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let date = entry.date {
                    Text(date, style: .date)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }

            Spacer()
        }
        .padding(18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(ColorTheme.accent.opacity(0.12), lineWidth: 5)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: CGFloat(entry.performanceScore) / 10.0)
                .stroke(
                    LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "22C55E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(entry.performanceScore)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("/10")
                    .font(.system(size: 10, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
    }

    // MARK: - Ratings

    private var ratingsRow: some View {
        HStack(spacing: 10) {
            ratingCard(label: "Focus", value: entry.focusRating, color: Color(hex: "3B82F6"))
            ratingCard(label: "Effort", value: entry.effortRating, color: Color(hex: "F97316"))
            ratingCard(label: "Confidence", value: entry.confidenceRating, color: Color(hex: "8B5CF6"))
        }
    }

    private func ratingCard(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(ratingColor(value))

            HStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < value ? color : color.opacity(0.12))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 6)

            Text(label)
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func ratingColor(_ value: Int) -> Color {
        switch value {
        case 8...10: return Color(hex: "22C55E")
        case 5...7: return ColorTheme.accent
        default: return Color(hex: "F97316")
        }
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
                .font(Typography.body)
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
