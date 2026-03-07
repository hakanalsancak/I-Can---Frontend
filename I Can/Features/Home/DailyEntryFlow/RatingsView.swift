import SwiftUI

struct RatingsView: View {
    @Binding var focus: Double
    @Binding var effort: Double
    @Binding var confidence: Double
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Rate Your Performance")
                            .font(Typography.title)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("Slide to rate each area")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    VStack(spacing: 12) {
                        SliderRating(title: "Focus", value: $focus)
                        SliderRating(title: "Effort", value: $effort)
                        SliderRating(title: "Confidence", value: $confidence)
                    }
                    .padding(.horizontal, 24)
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

                    PrimaryButton(title: "Continue") {
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
