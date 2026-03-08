import SwiftUI

struct SportSelectionView: View {
    @Binding var selectedSport: String
    let sports: [(id: String, name: String, icon: String)]
    let onNext: () -> Void
    let onBack: () -> Void
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
                        sportId: sport.id,
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

                PrimaryButton(
                    title: "Continue",
                    isDisabled: selectedSport.isEmpty
                ) {
                    withAnimation { onNext() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

private struct SportCard: View {
    let name: String
    let icon: String
    let sportId: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    private var sportColor: Color {
        switch sportId {
        case "soccer": return Color(hex: "22C55E")
        case "basketball": return Color(hex: "F97316")
        case "tennis": return Color(hex: "EAB308")
        case "football": return Color(hex: "8B4513")
        case "boxing": return Color(hex: "EF4444")
        case "cricket": return Color(hex: "3B82F6")
        default: return ColorTheme.accent
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? sportColor : ColorTheme.secondaryText(colorScheme))

                Text(name)
                    .font(Typography.subheadline)
                    .foregroundColor(isSelected ? sportColor : ColorTheme.primaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                isSelected
                ? sportColor.opacity(colorScheme == .dark ? 0.15 : 0.08)
                : ColorTheme.cardBackground(colorScheme)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? sportColor : ColorTheme.separator(colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? sportColor.opacity(0.2) : ColorTheme.cardShadow(colorScheme), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 3 : 1)
        }
        .buttonStyle(.plain)
    }
}
