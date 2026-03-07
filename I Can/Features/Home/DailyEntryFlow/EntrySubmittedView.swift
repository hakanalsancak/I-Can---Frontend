import SwiftUI

struct EntrySubmittedView: View {
    let response: EntrySubmitResponse
    let onDone: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showContent = false
    @State private var showStreak = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "22C55E").opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showContent ? 1 : 0.5)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .semibold).width(.condensed))
                        .foregroundColor(Color(hex: "22C55E"))
                        .scaleEffect(showContent ? 1 : 0.3)
                }
                .opacity(showContent ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Entry Saved")
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Performance Score")
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    Text("\(response.entry.performanceScore)")
                        .font(Typography.number(56))
                        .foregroundColor(ColorTheme.accent)
                }
                .opacity(showContent ? 1 : 0)

                if showStreak {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color(hex: "F97316"))
                            Text("\(response.streak.currentStreak) Day Streak")
                                .font(Typography.headline)
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        }
                        if response.streak.currentStreak >= response.streak.longestStreak
                            && response.streak.currentStreak > 1 {
                            Text("New personal best!")
                                .font(Typography.caption)
                                .foregroundColor(ColorTheme.accent)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(ColorTheme.subtleAccent(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer()
            Spacer()

            PrimaryButton(title: "Done") { onDone() }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
                showStreak = true
            }
            HapticManager.notification(.success)
        }
    }
}
