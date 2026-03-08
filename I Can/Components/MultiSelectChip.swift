import SwiftUI

struct MultiSelectChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(label)
                    .font(.system(size: 14, weight: .semibold).width(.condensed))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundColor(isSelected ? .white : ColorTheme.primaryText(colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? ColorTheme.accent : ColorTheme.cardBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.clear : ColorTheme.separator(colorScheme), lineWidth: 1)
            )
            .shadow(color: isSelected ? ColorTheme.accent.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct MultiSelectGrid: View {
    let items: [(label: String, icon: String?)]
    @Binding var selected: Set<String>

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items, id: \.label) { item in
                MultiSelectChip(
                    label: item.label,
                    icon: item.icon,
                    isSelected: selected.contains(item.label)
                ) {
                    HapticManager.selection()
                    if selected.contains(item.label) {
                        selected.remove(item.label)
                    } else {
                        selected.insert(item.label)
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
