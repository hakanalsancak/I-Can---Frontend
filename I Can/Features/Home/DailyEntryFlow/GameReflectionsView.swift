import SwiftUI

struct GameReflectionsView: View {
    let sport: String
    @Binding var bestMoment: String
    @Binding var biggestMistake: String
    @Binding var improveNextGame: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var prompts: (best: String, mistake: String, improve: String) {
        switch sport {
        case "soccer":
            return (
                "Best moment of the match",
                "Biggest mistake",
                "What will you improve next game"
            )
        case "basketball":
            return (
                "Best play you made",
                "What shot or play did you miss",
                "What will you improve next game"
            )
        case "tennis":
            return (
                "Best point played",
                "What part of your game broke down",
                "What will you improve next match"
            )
        case "football":
            return (
                "Best play",
                "Biggest mistake",
                "Improvement for next game"
            )
        case "cricket":
            return (
                "Best moment",
                "Toughest moment",
                "What to improve next match"
            )
        case "boxing":
            return (
                "Best combination landed",
                "Where defense failed",
                "What to improve next fight"
            )
        default:
            return (
                "Best moment",
                "Biggest mistake",
                "What to improve next time"
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Match Reflections")
                            .font(.system(size: 26, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("Replay the key moments")
                            .font(.system(size: 14, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    reflectionField(
                        label: prompts.best,
                        icon: "star.fill",
                        placeholder: "Describe it briefly...",
                        text: $bestMoment
                    )

                    reflectionField(
                        label: prompts.mistake,
                        icon: "exclamationmark.triangle",
                        placeholder: "What went wrong...",
                        text: $biggestMistake
                    )

                    reflectionField(
                        label: prompts.improve,
                        icon: "arrow.up.right",
                        placeholder: "One thing to work on...",
                        text: $improveNextGame
                    )
                }
                .padding(.bottom, 20)
            }

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

                PrimaryButton(title: "Continue") {
                    HapticManager.impact(.medium)
                    withAnimation { onNext() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func reflectionField(label: String, icon: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.system(size: 15, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .lineLimit(2...4)
                .padding(14)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                )
        }
        .padding(.horizontal, 24)
    }
}
