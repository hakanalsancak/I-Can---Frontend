import SwiftUI

struct SliderRating: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 1...10
    @Environment(\.colorScheme) private var colorScheme

    private var normalizedValue: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private var ratingColor: Color {
        switch Int(value) {
        case 8...10: return Color(hex: "22C55E")
        case 5...7: return ColorTheme.accent
        default: return Color(hex: "F97316")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Text("\(Int(value))")
                    .font(Typography.number(28))
                    .foregroundColor(ratingColor)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: value)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ColorTheme.separator(colorScheme))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ratingColor)
                        .frame(width: max(6, geo.size.width * normalizedValue), height: 6)
                }
            }
            .frame(height: 6)

            Slider(value: $value, in: range, step: 1) { Text(title) }
                .tint(ratingColor)
                .onChange(of: value) { _, _ in
                    HapticManager.selection()
                }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
