import SwiftUI

struct StreakBadge: View {
    let streak: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .semibold).width(.condensed))
                .foregroundColor(Color(hex: "F97316"))
            Text("\(streak)")
                .font(Typography.number(15, weight: .semibold))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
    }
}
