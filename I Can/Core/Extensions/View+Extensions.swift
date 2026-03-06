import SwiftUI

extension View {
    func cardStyle(_ colorScheme: ColorScheme) -> some View {
        self
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func primaryButtonStyle() -> some View {
        self
            .font(Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ColorTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
