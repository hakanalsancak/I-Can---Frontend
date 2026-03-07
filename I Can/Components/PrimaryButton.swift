import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonVariant = .filled
    let action: () -> Void

    enum ButtonVariant {
        case filled, outline
    }

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style == .filled ? .white : ColorTheme.accent)
                }
                Text(title)
                    .font(Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(overlayView)
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled:
            ColorTheme.accentGradient
        case .outline:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .outline: return ColorTheme.accent
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        if style == .outline {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.accent, lineWidth: 1.5)
        }
    }
}
