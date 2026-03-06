import SwiftUI

struct SportSelectionView: View {
    @Binding var selectedSport: String
    let sports: [(id: String, name: String, icon: String)]
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Choose Your Sport")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Select the sport you play")
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 24)

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
                        HapticManager.selection()
                        selectedSport = sport.id
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
            .padding(.bottom, 40)
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
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : ColorTheme.accent)

                Text(name)
                    .font(Typography.headline)
                    .foregroundColor(isSelected ? .white : ColorTheme.primaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? ColorTheme.accent : ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? ColorTheme.accent : .clear, lineWidth: 2)
            )
        }
    }
}
