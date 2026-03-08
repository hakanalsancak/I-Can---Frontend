import SwiftUI

struct EntryDetailView: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme

    private var r: EntryResponses? { entry.responses }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Label(entry.activityTypeDisplay, systemImage: entry.activityIcon)
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                PerformanceScoreCard(score: entry.performanceScore)
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)

            activitySpecificSection

            if let didWell = entry.didWell, !didWell.isEmpty {
                reflectionCard(title: "Did Well", icon: "hand.thumbsup", text: didWell)
            }

            if let improve = entry.improveNext, !improve.isEmpty {
                reflectionCard(title: "Improve Next", icon: "arrow.up.right", text: improve)
            }

            if let reflection = r?.recoveryReflection, !reflection.isEmpty {
                reflectionCard(title: "Recovery", icon: "heart.circle", text: reflection)
            }

            if let q = r?.rotatingQ, let a = r?.rotatingA {
                reflectionCard(title: q, icon: "questionmark.circle", text: a)
            }
        }
    }

    // MARK: - Activity-Specific

    @ViewBuilder
    private var activitySpecificSection: some View {
        if let r {
            switch entry.activityType {
            case "training":
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        labelPill(title: "Focus", label: r.focusLabel ?? "\(entry.focusRating)/10", color: Color(hex: "3B82F6"))
                        labelPill(title: "Effort", label: r.effortLabel ?? "\(entry.effortRating)/10", color: Color(hex: "F97316"))
                    }
                    if let w = r.workedOn, !w.isEmpty {
                        chipRow(chips: w)
                    }
                }
            case "game":
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        labelPill(title: "Pre-game", label: r.preGameFeeling ?? "\(entry.confidenceRating)/10", color: Color(hex: "8B5CF6"))
                        labelPill(title: "Performance", label: r.overallPerformance ?? "\(entry.focusRating)/10", color: Color(hex: "22C55E"))
                    }
                    if let s = r.strongestAreas, !s.isEmpty {
                        chipRow(chips: s)
                    }
                }
            case "rest_day":
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        labelPill(title: "Recovery", label: r.recoveryQuality ?? "\(entry.focusRating)/10", color: Color(hex: "3B82F6"))
                        labelPill(title: "Discipline", label: r.discipline ?? "\(entry.effortRating)/10", color: Color(hex: "22C55E"))
                    }
                    if let a = r.restActivities, !a.isEmpty {
                        chipRow(chips: a)
                    }
                }
            default:
                numericRow
            }
        } else {
            numericRow
        }
    }

    private var numericRow: some View {
        HStack(spacing: 10) {
            numericCard(label: "Focus", value: entry.focusRating)
            numericCard(label: "Effort", value: entry.effortRating)
            numericCard(label: "Confidence", value: entry.confidenceRating)
        }
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

    private func chipRow(chips: [String]) -> some View {
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

    private func numericCard(label: String, value: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(ratingColor(value))
            Text(label)
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
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

    private func reflectionCard(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text(text)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
