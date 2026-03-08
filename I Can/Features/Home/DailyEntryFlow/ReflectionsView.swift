import SwiftUI

struct ReflectionsView: View {
    @Binding var didWell: String
    @Binding var improveNext: String
    let onNext: () -> Void
    let onBack: () -> Void
    var isSubmitStep: Bool = false
    var isSubmitting: Bool = false
    var errorMessage: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Reflect")
                            .font(.system(size: 26, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("Quick reflections on your day")
                            .font(.system(size: 15, weight: .medium).width(.condensed))
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

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }
                }
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

                PrimaryButton(
                    title: isSubmitStep ? "Submit" : "Continue",
                    isLoading: isSubmitting
                ) {
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

struct RestReflectionStepView: View {
    @Binding var recoveryReflection: String
    let onNext: () -> Void
    let onBack: () -> Void
    var isSubmitting: Bool = false
    var errorMessage: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Recovery Reflection")
                            .font(.system(size: 26, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("Optional — anything that helped today")
                            .font(.system(size: 15, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("What helped you recover today?", systemImage: "heart.circle")
                            .font(.system(size: 15, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        TextField("e.g. Good sleep, stretching, hydration...", text: $recoveryReflection, axis: .vertical)
                            .font(.system(size: 15, weight: .regular).width(.condensed))
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

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }
                }
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

                PrimaryButton(
                    title: "Submit",
                    isLoading: isSubmitting
                ) {
                    HapticManager.impact(.medium)
                    onNext()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
