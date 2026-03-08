import SwiftUI

struct ChoiceOption: Identifiable {
    let id: String
    let label: String
    let icon: String
    let subtitle: String?

    init(_ label: String, icon: String, subtitle: String? = nil) {
        self.id = label
        self.label = label
        self.icon = icon
        self.subtitle = subtitle
    }
}

struct ChoiceCard: View {
    let option: ChoiceOption
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? ColorTheme.accent.opacity(0.15) : ColorTheme.elevatedBackground(colorScheme))
                        .frame(width: 48, height: 48)

                    Image(systemName: option.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(ColorTheme.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ColorTheme.cardBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? ColorTheme.accent : Color.clear, lineWidth: 2)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: isSelected ? 10 : 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
