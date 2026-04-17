import SwiftUI

struct AppMaintenanceView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onRetry: () async -> Void
    @State private var isRetrying = false

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "hammer.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(ColorTheme.accent)
                }

                VStack(spacing: 12) {
                    Text("Under Construction")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("I Can is temporarily unavailable while we make improvements. Please check back soon.")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }

                if isRetrying {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(ColorTheme.accent)
                        .padding(.top, 8)
                } else {
                    PrimaryButton(title: "Try Again") {
                        Task { await retry() }
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 8)
                }
            }
        }
    }

    private func retry() async {
        isRetrying = true
        await onRetry()
        isRetrying = false
    }
}
