import SwiftUI

struct GenderSelectionView: View {
    @Binding var gender: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let options = [
        ("male", "Male", "figure.stand"),
        ("female", "Female", "figure.stand.dress"),
        ("other", "Other", "person"),
        ("prefer_not_to_say", "Prefer not to say", "hand.raised"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("What's Your Gender?")
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Helps us personalize your experience")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)

            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            gender = option.0
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option.2)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(gender == option.0 ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))
                                .frame(width: 32)

                            Text(option.1)
                                .font(.system(size: 18, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            Spacer()

                            if gender == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            gender == option.0
                            ? ColorTheme.accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
                            : ColorTheme.cardBackground(colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    gender == option.0 ? ColorTheme.accent : ColorTheme.separator(colorScheme),
                                    lineWidth: gender == option.0 ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

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
                        isDisabled: gender.isEmpty
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
    }
}
