import SwiftUI

struct OptionalQuestionStepView: View {
    @Binding var answer: String
    let onSubmit: () -> Void
    let onBack: () -> Void
    var isSubmitting: Bool
    var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    private let options = [
        ChoiceOption("Yes", icon: "checkmark.circle.fill", subtitle: "Followed it completely"),
        ChoiceOption("Mostly", icon: "hand.thumbsup", subtitle: "Some adjustments were made"),
        ChoiceOption("No", icon: "xmark.circle", subtitle: "Went off plan today"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Did you follow your training plan today?")
                    .font(.system(size: 24, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("One last thing before saving")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(options) { option in
                    ChoiceCard(
                        option: option,
                        isSelected: answer == option.label
                    ) {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            answer = option.label
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }

            Spacer()

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
                    title: "Submit",
                    isLoading: isSubmitting
                ) {
                    HapticManager.impact(.medium)
                    onSubmit()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
