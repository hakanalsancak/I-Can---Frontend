import SwiftUI

struct RatingsView: View {
    @Binding var focus: Double
    @Binding var effort: Double
    @Binding var confidence: Double
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Rate Your Performance")
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Slide to rate each area (1-10)")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    SliderRating(title: "Focus", value: $focus)
                    SliderRating(title: "Effort", value: $effort)
                    SliderRating(title: "Confidence", value: $confidence)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

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
}
