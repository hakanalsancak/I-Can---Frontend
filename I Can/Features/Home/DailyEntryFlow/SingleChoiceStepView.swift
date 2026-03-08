import SwiftUI

struct SingleChoiceStepView: View {
    let question: String
    let subtitle: String
    let options: [ChoiceOption]
    @Binding var selection: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(question)
                    .font(.system(size: 24, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(options) { option in
                        ChoiceCard(
                            option: option,
                            isSelected: selection == option.label
                        ) {
                            HapticManager.impact(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = option.label
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation { onNext() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    HapticManager.impact(.light)
                    withAnimation { onBack() }
                } label: {
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(width: 100)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
