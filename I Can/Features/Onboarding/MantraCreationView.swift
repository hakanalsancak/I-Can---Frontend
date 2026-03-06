import SwiftUI

struct MantraCreationView: View {
    @Binding var mantra: String
    let examples: [String]
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create Your Mantra")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("A personal phrase to keep you focused")
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 24)

            TextField("Enter your mantra...", text: $mantra, axis: .vertical)
                .font(Typography.title3)
                .multilineTextAlignment(.center)
                .padding(20)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("Examples")
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .padding(.horizontal, 24)

                ForEach(examples, id: \.self) { example in
                    Button {
                        mantra = example
                        HapticManager.selection()
                    } label: {
                        Text("\"\(example)\"")
                            .font(Typography.callout)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Back") {
                    withAnimation { onBack() }
                }
                .font(Typography.headline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                PrimaryButton(title: "Continue") {
                    withAnimation { onNext() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
