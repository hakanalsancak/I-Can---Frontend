import SwiftUI

struct StreakBadge: View {
    let streak: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(streak)")
                .font(Typography.headline)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(Capsule())
    }
}
