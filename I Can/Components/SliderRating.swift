import SwiftUI

struct SliderRating: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 1...10
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Text("\(Int(value))")
                    .font(Typography.title2)
                    .foregroundColor(ColorTheme.accent)
                    .monospacedDigit()
            }

            Slider(value: $value, in: range, step: 1) {
                Text(title)
            }
            .tint(ColorTheme.accent)
            .onChange(of: value) { _, _ in
                HapticManager.selection()
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
