import SwiftUI

struct SportSelectionView: View {
    @Binding var selectedSport: String
    let sports: [(id: String, name: String, icon: String)]
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Choose Your Sport")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Select the sport you play")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(sports, id: \.id) { sport in
                    SportCard(
                        name: sport.name,
                        icon: sport.icon,
                        isSelected: selectedSport == sport.id,
                        colorScheme: colorScheme
                    ) {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSport = sport.id
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(
                title: "Continue",
                isDisabled: selectedSport.isEmpty
            ) {
                withAnimation { onNext() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

private struct SportCard: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium).width(.condensed))
                    .foregroundColor(isSelected ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))

                Text(name)
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                isSelected
                ? ColorTheme.subtleAccent(colorScheme)
                : ColorTheme.cardBackground(colorScheme)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? ColorTheme.accent : ColorTheme.separator(colorScheme),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
