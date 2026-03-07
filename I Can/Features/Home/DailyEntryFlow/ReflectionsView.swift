import SwiftUI

struct ReflectionsView: View {
    @Binding var didWell: String
    @Binding var improveNext: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Reflect")
                            .font(Typography.title)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("Quick reflections on your day")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    reflectionField(
                        label: "What did you do well today?",
                        icon: "hand.thumbsup",
                        placeholder: "e.g. Stayed focused during drills...",
                        text: $didWell
                    )

                    reflectionField(
                        label: "What will you improve next time?",
                        icon: "arrow.up.right",
                        placeholder: "e.g. Work on first touch accuracy...",
                        text: $improveNext
                    )
                }
            }

            VStack(spacing: 0) {
                Divider().opacity(0.3)
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

                    PrimaryButton(title: "Continue") {
                        withAnimation { onNext() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
    }

    private func reflectionField(label: String, icon: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(Typography.headline)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            TextField(placeholder, text: text, axis: .vertical)
                .font(Typography.body)
                .lineLimit(3...6)
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
