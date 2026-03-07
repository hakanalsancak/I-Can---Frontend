import SwiftUI
import Combine

private let iCanQuotes: [String] = [
    "I can push through when it gets hard.",
    "I can stay focused under pressure.",
    "I can turn mistakes into lessons.",
    "I can give 100% every single day.",
    "I can control my effort.",
    "I can stay disciplined when no one is watching.",
    "I can be better than yesterday.",
    "I can rise after every fall.",
    "I can trust my preparation.",
    "I can silence the doubt.",
    "I can outwork the competition.",
    "I can show up when it matters most.",
    "I can stay calm in the storm.",
    "I can embrace the grind.",
    "I can lead by example.",
    "I can keep going when others quit.",
    "I can earn it every day.",
    "I can handle the pressure.",
    "I can find a way.",
    "I can be relentless.",
    "I can stay patient with my progress.",
    "I can commit fully to my goals.",
    "I can choose discipline over comfort.",
    "I can compete with myself.",
    "I can overcome any obstacle.",
    "I can finish stronger than I started.",
    "I can take the next step.",
    "I can do the work nobody sees.",
    "I can be consistent day after day.",
    "I can believe in my abilities.",
    "I can recover and come back stronger.",
    "I can focus on what I control.",
    "I can block out distractions.",
    "I can set the standard.",
    "I can prove it on the field.",
    "I can deliver when the stakes are high.",
    "I can build unshakeable confidence.",
    "I can embrace the challenge.",
    "I can fuel my body for performance.",
    "I can learn from every rep.",
    "I can sharpen my skills daily.",
    "I can play with intensity.",
    "I can maintain my composure.",
    "I can visualize my success.",
    "I can train my mind like my body.",
    "I can dominate the details.",
    "I can stay hungry for growth.",
    "I can respect the process.",
    "I can make my teammates better.",
    "I can own the moment.",
    "I can channel my energy.",
    "I can put the team first.",
    "I can perform at my peak.",
    "I can turn fear into fuel.",
    "I can adapt to any situation.",
    "I can be mentally tough.",
    "I can stay locked in.",
    "I can win the day.",
    "I can accept feedback and improve.",
    "I can play without fear.",
    "I can thrive in adversity.",
    "I can prepare like a professional.",
    "I can control my attitude.",
    "I can bring energy every session.",
    "I can chase greatness.",
    "I can make the most of today.",
    "I can stay committed to the process.",
    "I can trust my training.",
    "I can be the hardest worker in the room.",
    "I can compete at the highest level.",
    "I can bounce back from setbacks.",
    "I can stay positive through struggles.",
    "I can execute under fatigue.",
    "I can be coachable.",
    "I can take responsibility.",
    "I can push past my limits.",
    "I can control my breathing.",
    "I can stay present in the moment.",
    "I can perform with purpose.",
    "I can make every practice count.",
    "I can develop a winner's mindset.",
    "I can master my emotions.",
    "I can stay laser-focused.",
    "I can choose growth over comfort.",
    "I can put in extra work.",
    "I can be fearless on the field.",
    "I can celebrate small wins.",
    "I can learn from losses.",
    "I can play with heart.",
    "I can keep my body strong.",
    "I can be a student of the game.",
    "I can build lasting habits.",
    "I can stay motivated from within.",
    "I can be accountable to myself.",
    "I can transform pressure into power.",
    "I can give everything I have.",
    "I can write my own story.",
    "I can become unstoppable.",
    "I can finish what I started.",
    "I can make today legendary.",
]

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var currentQuoteIndex = Int.random(in: 0..<iCanQuotes.count)
    @State private var quoteOpacity: Double = 1
    @State private var showSubscription = false
    @State private var showBreathing = false
    @Environment(\.colorScheme) private var colorScheme

    private let quoteTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Home")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        quoteSection

                        if !SubscriptionService.shared.isPremium {
                            AIReportPromoCard(style: .home) {
                                showSubscription = true
                            }
                        }

                        dailyEntryCard
                        streakSection
                        mentalToolsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable { await viewModel.loadData() }
            .task { await viewModel.loadData() }
            .fullScreenCover(isPresented: $viewModel.showDailyEntry) {
                DailyEntryFlowView { response in
                    viewModel.onEntrySubmitted(response: response)
                }
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingExerciseView()
            }
            .onReceive(quoteTimer) { _ in
                rotateQuote()
            }
        }
    }

    // MARK: - Motivational Quote

    private var quoteSection: some View {
        VStack {
            Spacer()
            Text(iCanQuotes[currentQuoteIndex])
                .font(.system(size: 28, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .opacity(quoteOpacity)
                .id(currentQuoteIndex)
                .padding(.horizontal, 28)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private func rotateQuote() {
        withAnimation(.easeOut(duration: 0.4)) {
            quoteOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var nextIndex: Int
            repeat {
                nextIndex = Int.random(in: 0..<iCanQuotes.count)
            } while nextIndex == currentQuoteIndex
            currentQuoteIndex = nextIndex
            withAnimation(.easeIn(duration: 0.4)) {
                quoteOpacity = 1
            }
        }
    }

    // MARK: - Daily Entry

    private var dailyEntryCard: some View {
        Button {
            viewModel.showDailyEntry = true
            HapticManager.impact(.medium)
        } label: {
            if viewModel.hasLoggedToday {
                loggedCard
            } else {
                notLoggedCard
            }
        }
        .buttonStyle(.plain)
    }

    private var notLoggedCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ColorTheme.accentGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: ColorTheme.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Log Today's Performance")
                        .font(Typography.title3)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Track your focus, effort & confidence")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                Spacer()
            }

            HStack(spacing: 20) {
                miniMetric(icon: "scope", label: "Focus")
                miniDivider
                miniMetric(icon: "bolt.fill", label: "Effort")
                miniDivider
                miniMetric(icon: "shield.fill", label: "Confidence")
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(ColorTheme.elevatedBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .medium))
                Text("Takes less than 2 minutes")
                    .font(Typography.caption)
            }
            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(20)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 10, x: 0, y: 3)
    }

    private var miniDivider: some View {
        Rectangle()
            .fill(ColorTheme.separator(colorScheme))
            .frame(width: 1, height: 24)
    }

    private func miniMetric(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorTheme.accent)
            Text(label)
                .font(.system(size: 11, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private var loggedCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "22C55E"))
                        .frame(width: 40, height: 40)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance Logged")
                        .font(Typography.headline)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Tap to view or update your entry")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(16)

            if let entry = viewModel.todayEntry {
                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack(spacing: 0) {
                    inlineRating(label: "Focus", value: entry.focusRating)
                    inlineRating(label: "Effort", value: entry.effortRating)
                    inlineRating(label: "Confidence", value: entry.confidenceRating)
                    inlineScore(value: entry.performanceScore)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
            }
        }
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: "22C55E").opacity(0.2), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private func inlineRating(label: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(Typography.number(20))
                .foregroundColor(ratingColor(value))
            Text(label)
                .font(.system(size: 10, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private func inlineScore(value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(Typography.number(20))
                .foregroundStyle(ColorTheme.accentGradient)
            Text("Score")
                .font(.system(size: 10, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.accent)
        }
        .frame(maxWidth: .infinity)
    }

    private func ratingColor(_ value: Int) -> Color {
        switch value {
        case 8...10: return Color(hex: "22C55E")
        case 5...7: return ColorTheme.accent
        default: return Color(hex: "F97316")
        }
    }

    // MARK: - Streaks

    private var streakSection: some View {
        HStack(spacing: 12) {
            streakCard(
                title: "Current Streak",
                value: viewModel.streak?.currentStreak ?? 0,
                icon: "flame.fill",
                iconColor: Color(hex: "F97316")
            )
            streakCard(
                title: "Best Streak",
                value: viewModel.streak?.longestStreak ?? 0,
                icon: "trophy.fill",
                iconColor: Color(hex: "EAB308")
            )
        }
    }

    private func streakCard(title: String, value: Int, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }
            Text("\(value)")
                .font(Typography.number(32))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text(value == 1 ? "day" : "days")
                .font(Typography.caption)
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    // MARK: - Mental Tools

    private var mentalToolsSection: some View {
        VStack(spacing: 12) {
            Text("MENTAL TOOLS")
                .sectionHeader(colorScheme)

            Button { showBreathing = true } label: {
                mentalToolTile(
                    icon: "wind",
                    title: "Breathing Exercise",
                    color: Color(hex: "3B82F6")
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func mentalToolTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)

            Text(title)
                .font(.system(size: 12, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
