import SwiftUI

struct RotatingQuestionView: View {
    let question: (id: Int, text: String, type: String)
    @Binding var textAnswer: String
    @Binding var sliderValue: Double
    let isSlider: Bool
    let onSubmit: () -> Void
    let onBack: () -> Void
    var isSubmitting: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Daily Question")
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("One more thing...")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 32)

                if isSlider {
                    SliderRating(title: question.text, value: $sliderValue)
                        .padding(.horizontal, 24)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.text)
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        TextField("Your answer...", text: $textAnswer, axis: .vertical)
                            .font(Typography.body)
                            .lineLimit(3...6)
                            .padding(16)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)

                HStack(spacing: 12) {
                    Button("Back") {
                        withAnimation { onBack() }
                    }
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                    PrimaryButton(title: "Submit", isLoading: isSubmitting) {
                        onSubmit()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
