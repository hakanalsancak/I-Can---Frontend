import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedType: String
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let types = [
        ("training", "Training", "figure.run", "Practice, drills, conditioning"),
        ("game", "Game", "trophy", "Match, competition, scrimmage"),
        ("rest_day", "Rest Day", "moon.stars", "Recovery, stretching, off day"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("What happened today?")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Select your activity type")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            VStack(spacing: 10) {
                ForEach(types, id: \.0) { type in
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type.0
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: type.2)
                                .font(.system(size: 20, weight: .medium).width(.condensed))
                                .foregroundColor(selectedType == type.0 ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedType == type.0
                                    ? ColorTheme.subtleAccent(colorScheme)
                                    : ColorTheme.elevatedBackground(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.1)
                                    .font(Typography.headline)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                Text(type.3)
                                    .font(Typography.footnote)
                                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            }

                            Spacer()

                            if selectedType == type.0 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold).width(.condensed))
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                        .padding(14)
                        .background(
                            selectedType == type.0
                            ? ColorTheme.subtleAccent(colorScheme)
                            : ColorTheme.cardBackground(colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    selectedType == type.0 ? ColorTheme.accent.opacity(0.4) : ColorTheme.separator(colorScheme),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(
                title: "Continue",
                isDisabled: selectedType.isEmpty
            ) {
                withAnimation { onNext() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
