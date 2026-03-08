import SwiftUI

struct MantraCreationView: View {
    @Binding var mantra: String
    let examples: [(quote: String, athlete: String)]
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Create Your Mantra")
                            .font(Typography.title)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("A personal phrase to keep you focused")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 32)

                    TextField("Enter your mantra...", text: $mantra, axis: .vertical)
                        .font(Typography.title3)
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                        )
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("INSPIRED BY THE GREATS")
                            .sectionHeader(colorScheme)
                            .padding(.horizontal, 24)

                        ForEach(examples, id: \.quote) { example in
                            Button {
                                mantra = example.quote
                                HapticManager.impact(.light)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "quote.opening")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(ColorTheme.accent)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\"\(example.quote)\"")
                                            .font(.system(size: 15, weight: .semibold).width(.condensed))
                                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                                        Text("— \(example.athlete)")
                                            .font(.system(size: 12, weight: .medium).width(.condensed))
                                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                    }

                                    Spacer()

                                    if mantra == example.quote {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(ColorTheme.accent)
                                    }
                                }
                                .padding(14)
                                .background(
                                    mantra == example.quote
                                    ? ColorTheme.subtleAccent(colorScheme)
                                    : ColorTheme.cardBackground(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            mantra == example.quote ? ColorTheme.accent.opacity(0.3) : ColorTheme.separator(colorScheme),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                Divider().opacity(0.3)
                VStack(spacing: 8) {
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
                            isDisabled: mantra.trimmingCharacters(in: .whitespaces).isEmpty
                        ) {
                            withAnimation { onNext() }
                        }
                    }

                    Button {
                        mantra = ""
                        withAnimation { onNext() }
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 13, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
    }
}
