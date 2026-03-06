import SwiftUI

struct NotificationFrequencyView: View {
    @Binding var frequency: Int
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let options = [
        (0, "No notifications"),
        (1, "1 per day"),
        (2, "2 per day"),
        (3, "3 per day"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Stay Motivated")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("How many motivational reminders\nwould you like per day?")
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button {
                        HapticManager.selection()
                        frequency = option.0
                    } label: {
                        HStack {
                            Text(option.1)
                                .font(Typography.headline)
                                .foregroundColor(
                                    frequency == option.0
                                    ? .white
                                    : ColorTheme.primaryText(colorScheme)
                                )
                            Spacer()
                            if frequency == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(
                            frequency == option.0
                            ? ColorTheme.accent
                            : ColorTheme.cardBackground(colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 24)

            CardView {
                VStack(spacing: 8) {
                    Text("\"I Can stay focused under pressure.\"")
                        .font(Typography.callout)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .italic()
                    Text("Example notification")
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 12) {
                Button("Back") {
                    withAnimation { onBack() }
                }
                .font(Typography.headline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                PrimaryButton(title: "Continue") {
                    withAnimation { onNext() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
