import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(ColorTheme.accent)
            if !message.isEmpty {
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTheme.background(colorScheme))
    }
}
