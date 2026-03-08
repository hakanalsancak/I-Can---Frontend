import SwiftUI

struct NameEntryView: View {
    @Binding var name: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("What's Your Name?")
                        .font(.system(size: 28, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("We'll use this to personalize your experience")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                TextField("Your first name", text: $name)
                    .font(.system(size: 22, weight: .bold).width(.condensed))
                    .multilineTextAlignment(.center)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isFocused ? ColorTheme.accent.opacity(0.4) : ColorTheme.separator(colorScheme),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()

            VStack(spacing: 0) {
                Divider().opacity(0.3)
                HStack(spacing: 12) {
                    Button {
                        withAnimation { onBack() }
                    } label: {
                        Text("Back")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }

                    PrimaryButton(
                        title: "Continue",
                        isDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        withAnimation { onNext() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
        .onAppear { isFocused = true }
    }
}
