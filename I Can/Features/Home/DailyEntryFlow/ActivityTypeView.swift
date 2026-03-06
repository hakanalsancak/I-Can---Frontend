import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedType: String
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let types = [
        ("training", "Training", "figure.run", "Practice, drills, conditioning"),
        ("game", "Game", "trophy", "Match, competition, scrimmage"),
        ("rest_day", "Rest Day", "bed.double", "Recovery, stretching, off day"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What happened today?")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Select your activity type")
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)

            VStack(spacing: 12) {
                ForEach(types, id: \.0) { type in
                    Button {
                        HapticManager.selection()
                        selectedType = type.0
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: type.2)
                                .font(.title2)
                                .foregroundColor(selectedType == type.0 ? .white : ColorTheme.accent)
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedType == type.0
                                    ? ColorTheme.accent
                                    : ColorTheme.accent.opacity(0.1)
                                )
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.1)
                                    .font(Typography.headline)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                Text(type.3)
                                    .font(Typography.caption)
                                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            }

                            Spacer()

                            if selectedType == type.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedType == type.0 ? ColorTheme.accent : .clear, lineWidth: 2)
                        )
                    }
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
            .padding(.bottom, 40)
        }
    }
}
