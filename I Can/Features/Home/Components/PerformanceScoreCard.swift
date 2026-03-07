import SwiftUI

struct PerformanceScoreCard: View {
    let score: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(ColorTheme.separator(colorScheme), lineWidth: 6)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        scoreGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(Typography.number(26))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }

            Text(scoreLabel)
                .font(Typography.caption)
                .foregroundColor(scoreColor)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = CGFloat(score) / 10.0
            }
        }
    }

    private var scoreColor: Color {
        switch score {
        case 8...10: return Color(hex: "22C55E")
        case 5...7: return ColorTheme.accent
        default: return Color(hex: "F97316")
        }
    }

    private var scoreGradient: AngularGradient {
        AngularGradient(
            colors: [scoreColor.opacity(0.6), scoreColor],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    private var scoreLabel: String {
        switch score {
        case 8...10: return "Great"
        case 5...7: return "Good"
        default: return "Keep Going"
        }
    }
}
