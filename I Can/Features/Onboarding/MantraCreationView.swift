import SwiftUI

struct MantraCreationView: View {
    @Binding var mantra: String
    let examples: [String]
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
                        Text("SUGGESTIONS")
                            .sectionHeader(colorScheme)
                            .padding(.horizontal, 24)

                        ForEach(examples, id: \.self) { example in
                            Button {
                                mantra = example
                                HapticManager.impact(.light)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "quote.opening")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.accent)
                                    Text(example)
                                        .font(Typography.callout)
                                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(14)
                                .background(ColorTheme.cardBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
}
