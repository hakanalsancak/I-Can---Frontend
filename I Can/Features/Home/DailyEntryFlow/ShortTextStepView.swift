import SwiftUI

struct ShortTextStepView: View {
    let question: String
    let subtitle: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    let onNext: () -> Void
    let onBack: () -> Void
    var isOptional: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(ColorTheme.accent)
                            .padding(.bottom, 4)

                        Text(question)
                            .font(.system(size: 24, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    TextField(placeholder, text: $text, axis: .vertical)
                        .font(.system(size: 16, weight: .medium).width(.condensed))
                        .lineLimit(2...4)
                        .focused($isFocused)
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isFocused ? ColorTheme.accent.opacity(0.4) : ColorTheme.separator(colorScheme),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                        .padding(.horizontal, 24)

                    if isOptional {
                        Text("Optional — skip if you prefer")
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    HapticManager.impact(.light)
                    withAnimation { onBack() }
                } label: {
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(width: 100)

                PrimaryButton(
                    title: "Continue",
                    isDisabled: !isOptional && text.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    HapticManager.impact(.medium)
                    withAnimation { onNext() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear { isFocused = true }
    }
}
