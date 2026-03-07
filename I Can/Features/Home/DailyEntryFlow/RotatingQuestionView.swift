import SwiftUI

struct RotatingQuestionView: View {
    let question: (id: Int, text: String, type: String)
    @Binding var textAnswer: String
    @Binding var sliderValue: Double
    let isSlider: Bool
    let onSubmit: () -> Void
    let onBack: () -> Void
    var isSubmitting: Bool
    var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Daily Question")
                            .font(Typography.title)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("One more thing...")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    if isSlider {
                        SliderRating(title: question.text, value: $sliderValue)
                            .padding(.horizontal, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(question.text)
                                .font(Typography.headline)
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            TextField("Your answer...", text: $textAnswer, axis: .vertical)
                                .font(Typography.body)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(ColorTheme.cardBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Typography.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
            }

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

                    PrimaryButton(title: "Submit", isLoading: isSubmitting) {
                        onSubmit()
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
