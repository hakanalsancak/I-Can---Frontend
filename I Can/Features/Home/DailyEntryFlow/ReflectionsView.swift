import SwiftUI

struct ReflectionsView: View {
    @Binding var didWell: String
    @Binding var improveNext: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Reflect")
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Quick reflections on your day")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 32)

                VStack(alignment: .leading, spacing: 8) {
                    Label("What did you do well today?", systemImage: "hand.thumbsup")
                        .font(Typography.headline)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    TextField("e.g. Stayed focused during drills...", text: $didWell, axis: .vertical)
                        .font(Typography.body)
                        .lineLimit(3...6)
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Label("What will you improve next time?", systemImage: "arrow.up.circle")
                        .font(Typography.headline)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    TextField("e.g. Work on first touch accuracy...", text: $improveNext, axis: .vertical)
                        .font(Typography.body)
                        .lineLimit(3...6)
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

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
}
