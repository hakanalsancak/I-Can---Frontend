import SwiftUI

extension View {
    func cardStyle(_ colorScheme: ColorScheme) -> some View {
        self
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    func primaryButtonStyle() -> some View {
        self
            .font(Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ColorTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func sectionHeader(_ colorScheme: ColorScheme) -> some View {
        self
            .font(Typography.caption)
            .foregroundColor(ColorTheme.secondaryText(colorScheme))
            .textCase(.uppercase)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
