import SwiftUI

struct EntrySubmittedView: View {
    let response: EntrySubmitResponse
    var coachInsight: String = ""
    var isLoadingInsight: Bool = false
    let onDone: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showContent = false
    @State private var showStreak = false
    @State private var showInsight = false
    @State private var showSubscription = false

    private var isPremium: Bool { SubscriptionService.shared.isPremium }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
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

                Text("Daily Reflection Saved")
                    .font(.system(size: 22, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .opacity(showContent ? 1 : 0)

                if showStreak {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color(hex: "F97316"))
                            Text("\(response.streak.currentStreak) Day Streak")
                                .font(.system(size: 16, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        }
                        if response.streak.currentStreak >= response.streak.longestStreak
                            && response.streak.currentStreak > 1 {
                            Text("New personal best!")
                                .font(.system(size: 12, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(ColorTheme.subtleAccent(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
                }

                if showInsight {
                    if isPremium {
                        insightCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        lockedInsightCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
            withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
                showStreak = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                showInsight = true
            }
            HapticManager.notification(.success)
            ReviewManager.recordEntrySubmitted()
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            ReviewManager.requestReviewIfAppropriate()
        }
        .sheet(isPresented: $showSubscription, onDismiss: {
            Task { try? await SubscriptionService.shared.checkStatus() }
        }) {
            SubscriptionView()
        }
    }

    // MARK: - Premium Insight Card

    private var insightCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                Text("TODAY'S COACH INSIGHT")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
            }
            .foregroundColor(ColorTheme.accent)

            if isLoadingInsight {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(ColorTheme.accent)
                        .scaleEffect(0.8)
                    Text("Your coach is analyzing...")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.vertical, 4)
            } else if !coachInsight.isEmpty {
                Text(coachInsight)
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            } else {
                Text("Every entry builds the bigger picture. Keep showing up.")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 24)
    }

    // MARK: - Locked Insight Card (Free Users)

    private var lockedInsightCard: some View {
        Button {
            showSubscription = true
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("COACH INSIGHT")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                }
                .foregroundColor(Color(hex: "8B5CF6"))

                Text("Get personalized AI coaching after every log")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Unlock Premium")
                        .font(.system(size: 12, weight: .heavy).width(.condensed))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }
}
