import SwiftUI

struct ForceUpdateView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Replace with your numeric App Store ID
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6760717419")!

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(ColorTheme.accent)
                }

                VStack(spacing: 12) {
                    Text("Update Required")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("A new version of I Can is available. Please update to continue using the app.")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }

                PrimaryButton(title: "Update Now") {
                    UIApplication.shared.open(appStoreURL)
                }
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }
        }
    }
}
