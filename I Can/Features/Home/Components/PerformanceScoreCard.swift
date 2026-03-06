import SwiftUI

struct PerformanceScoreCard: View {
    let score: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(ColorTheme.cardBackground(colorScheme), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }

            Text(scoreLabel)
                .font(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
    }

    private var scoreColor: Color {
        switch score {
        case 8...10: return .green
        case 5...7: return .orange
        default: return .red
        }
    }

    private var scoreLabel: String {
        switch score {
        case 8...10: return "Great!"
        case 5...7: return "Good"
        default: return "Keep Going"
        }
    }
}
