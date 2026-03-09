import SwiftUI

struct TodayEntryDetailSheet: View {
    let entry: DailyEntry
    var onEdit: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var r: EntryResponses? { entry.responses }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard

                    activitySpecificSection

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

                    if let reflection = r?.recoveryReflection, !reflection.isEmpty {
                        reflectionCard(
                            title: "Recovery reflection",
                            icon: "heart.circle.fill",
                            text: reflection,
                            color: ColorTheme.accent
                        )
                    }

                    if let q = r?.rotatingQ, let a = r?.rotatingA {
                        reflectionCard(title: q, icon: "questionmark.circle.fill", text: a, color: Color(hex: "8B5CF6"))
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
                .trim(from: 0, to: CGFloat(entry.performanceScore) / 100.0)
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
                Text("/100")
                    .font(.system(size: 10, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
    }

    // MARK: - Activity-Specific Section

    @ViewBuilder
    private var activitySpecificSection: some View {
        if let r {
            switch entry.activityType {
            case "training":
                trainingSection(r)
            case "game":
                gameSection(r)
            case "rest_day":
                restSection(r)
            default:
                numericFallback
            }
        } else {
            numericFallback
        }
    }

    private func trainingSection(_ r: EntryResponses) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                labelCard(title: "FOCUS", label: r.focusLabel ?? "\(entry.focusRating)/10", color: Color(hex: "3B82F6"))
                labelCard(title: "EFFORT", label: r.effortLabel ?? "\(entry.effortRating)/10", color: Color(hex: "F97316"))
            }

            if let worked = r.workedOn, !worked.isEmpty {
                chipSection(title: "WORKED ON", chips: worked, color: ColorTheme.accent)
            }
        }
    }

    private func gameSection(_ r: EntryResponses) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                labelCard(title: "PRE-GAME", label: r.preGameFeeling ?? "\(entry.confidenceRating)/10", color: Color(hex: "8B5CF6"))
                labelCard(title: "PERFORMANCE", label: r.overallPerformance ?? "\(entry.focusRating)/10", color: Color(hex: "22C55E"))
            }

            if let strongest = r.strongestAreas, !strongest.isEmpty {
                chipSection(title: "STRONGEST", chips: strongest, color: Color(hex: "22C55E"))
            }
        }
    }

    private func restSection(_ r: EntryResponses) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                labelCard(title: "RECOVERY", label: r.recoveryQuality ?? "\(entry.focusRating)/10", color: Color(hex: "3B82F6"))
                labelCard(title: "DISCIPLINE", label: r.discipline ?? "\(entry.effortRating)/10", color: Color(hex: "22C55E"))
            }

            if let activities = r.restActivities, !activities.isEmpty {
                chipSection(title: "ACTIVITIES", chips: activities, color: ColorTheme.accent)
            }
        }
    }

    private var numericFallback: some View {
        HStack(spacing: 10) {
            numericCard(label: "Focus", value: entry.focusRating, color: Color(hex: "3B82F6"))
            numericCard(label: "Effort", value: entry.effortRating, color: Color(hex: "F97316"))
            numericCard(label: "Confidence", value: entry.confidenceRating, color: Color(hex: "8B5CF6"))
        }
    }

    // MARK: - Label Card

    private func labelCard(title: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            Text(label)
                .font(.system(size: 15, weight: .bold).width(.condensed))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
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

    // MARK: - Numeric Fallback Card

    private func numericCard(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(ratingColor(value))
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
