import SwiftUI

struct EntrySubmittedView: View {
    let response: EntrySubmitResponse
    let onDone: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showScore = false
    @State private var showStreak = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .scaleEffect(showScore ? 1 : 0.5)
                    .opacity(showScore ? 1 : 0)

                Text("Entry Saved!")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .opacity(showScore ? 1 : 0)
            }

            if showScore {
                VStack(spacing: 8) {
                    Text("Performance Score")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    Text("\(response.entry.performanceScore)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(ColorTheme.accent)
                }
                .transition(.scale.combined(with: .opacity))
            }

            if showStreak {
                VStack(spacing: 4) {
                    Text("🔥 \(response.streak.currentStreak) Day Performance Streak")
                        .font(Typography.title3)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    if response.streak.currentStreak >= response.streak.longestStreak
                        && response.streak.currentStreak > 1 {
                        Text("New personal best!")
                            .font(Typography.caption)
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()

            PrimaryButton(title: "Done") {
                onDone()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                showScore = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showStreak = true
            }
            HapticManager.notification(.success)
        }
    }
}
