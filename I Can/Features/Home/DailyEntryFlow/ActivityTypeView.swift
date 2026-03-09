import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedType: String
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let types: [(id: String, label: String, icon: String, subtitle: String)] = [
        ("training", "Training", "figure.run", "Practice, drills, conditioning"),
        ("game", "Game", "trophy", "Match, competition, scrimmage"),
        ("rest_day", "Rest Day", "moon.stars", "Recovery, stretching, off day"),
        ("other", "Something Else", "ellipsis.circle", "Mixed day, multiple activities, etc."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("What happened today?")
                    .font(.system(size: 26, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Select your activity type")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 40)
            .padding(.bottom, 36)

            VStack(spacing: 12) {
                ForEach(types, id: \.id) { type in
                    ChoiceCard(
                        option: ChoiceOption(type.label, icon: type.icon, subtitle: type.subtitle),
                        isSelected: selectedType == type.id
                    ) {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type.id
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { onNext() }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
