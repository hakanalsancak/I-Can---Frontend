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
    @Bindable private var viewModel = HomeViewModel.shared
    @Binding var selectedTab: Int
    @State private var currentQuoteIndex = Int.random(in: 0..<iCanQuotes.count)
    @State private var quoteOpacity: Double = 1
    @State private var showSubscription = false
    @State private var showBreathing = false
    @State private var showProfile = false
    @State private var profileImage: UIImage? = nil
    @State private var heroAppeared = false

    // Legacy entry flow support
    @State private var showEntryDetail = false
    @State private var editingEntry = false

    @Environment(\.colorScheme) private var colorScheme

    private let quoteTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                homeHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        mantraCard
                            .padding(.top, 16)

                        // DAILY LOG SECTION - PRIMARY FOCUS
                        dailyLogSection

                        // PROGRESS TRACKER
                        progressTracker

                        // PERFORMANCE DASHBOARD
                        PerformanceDashboardView(
                            weeklyData: viewModel.weeklyAnalytics,
                            monthlyData: viewModel.monthlyAnalytics,
                            previousMonthData: viewModel.previousMonthAnalytics,
                            isLoading: viewModel.isLoadingAnalytics
                        )

                        // STREAK SECTION
                        streakSection

                        // BREATHING - COMPACT
                        compactBreatheCard

                        if SubscriptionService.shared.statusChecked && !SubscriptionService.shared.isPremium {
                            aiCoachPromo
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable { await viewModel.loadData() }
            .task { await viewModel.loadData() }
            .alert("Save Error", isPresented: Binding<Bool>(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveError ?? "")
            }
            .sheet(isPresented: $viewModel.showTrainingLog) {
                TrainingLogView(existingData: viewModel.todayTraining) { data in
                    Task { await viewModel.submitTraining(data) }
                }
            }
            .sheet(isPresented: $viewModel.showNutritionLog) {
                NutritionLogView(existingData: viewModel.todayNutrition) { data in
                    Task { await viewModel.submitNutrition(data) }
                }
            }
            .sheet(isPresented: $viewModel.showSleepLog) {
                SleepLogView(existingData: viewModel.todaySleep) { data in
                    Task { await viewModel.submitSleep(data) }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showDailyEntry, onDismiss: {
                Task { await viewModel.loadData() }
            }) {
                DailyEntryFlowView(
                    existingEntry: editingEntry ? viewModel.todayEntry : nil
                ) { response in
                    viewModel.onEntrySubmitted(response: response)
                    editingEntry = false
                }
            }
            .sheet(isPresented: $showSubscription, onDismiss: {
                Task { try? await SubscriptionService.shared.checkStatus() }
            }) {
                SubscriptionView()
            }
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingExerciseView()
            }
            .sheet(isPresented: $showEntryDetail) {
                if let entry = viewModel.todayEntry {
                    TodayEntryDetailSheet(entry: entry) {
                        editingEntry = true
                        viewModel.showDailyEntry = true
                    }
                }
            }
            .onReceive(quoteTimer) { _ in
                rotateQuote()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    heroAppeared = true
                }
                loadProfileImage()
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == 0 {
                    Task { await viewModel.refreshIfNeeded() }
                }
            }
            .sheet(isPresented: $showProfile, onDismiss: {
                loadProfileImage()
            }) {
                ProfileView()
            }
        }
    }

    private func loadProfileImage() {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = dir.appendingPathComponent("profile_photo_\(userId).jpg")
        Task {
            let image = await Task.detached(priority: .userInitiated) {
                guard let data = try? Data(contentsOf: url) else { return nil as UIImage? }
                return UIImage(data: data)
            }.value
            await MainActor.run {
                profileImage = image
            }
        }
    }

    // MARK: - Header

    private var homeHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greetingText)
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    Text(firstName)
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                Spacer()

                HStack(spacing: 10) {
                    streakBadge

                    Button {
                        HapticManager.selection()
                        showProfile = true
                    } label: {
                        profileAvatarSmall
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 14)

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)
        }
        .background(ColorTheme.background(colorScheme))
    }

    private var profileAvatarSmall: some View {
        ZStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTheme.accent.opacity(0.25), ColorTheme.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)

                Text(profileInitials)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(ColorTheme.accent)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(ColorTheme.accent.opacity(0.3), lineWidth: 1.5)
                .frame(width: 36, height: 36)
        )
    }

    private var profileInitials: String {
        guard let name = AuthService.shared.currentUser?.fullName, !name.isEmpty else { return "?" }
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var firstName: String {
        guard let full = AuthService.shared.currentUser?.fullName,
              !full.isEmpty else { return "Athlete" }
        return full.components(separatedBy: " ").first ?? full
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "F97316"))
            Text("\(viewModel.streak?.currentStreak ?? 0)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "F97316").opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Mantra Card

    private var mantraCard: some View {
        VStack(spacing: 0) {
            Text(iCanQuotes[currentQuoteIndex])
                .font(.system(size: 18, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(quoteOpacity)
                .id(currentQuoteIndex)
                .frame(minHeight: 44)

            if let mantra = AuthService.shared.currentUser?.mantra, !mantra.isEmpty {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(ColorTheme.accent)
                        .frame(width: 12, height: 2)
                    Text("Your mantra: \(mantra)")
                        .font(.system(size: 12, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                    Rectangle()
                        .fill(ColorTheme.accent)
                        .frame(width: 12, height: 2)
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [ColorTheme.accent.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    private func rotateQuote() {
        withAnimation(.easeOut(duration: 0.4)) {
            quoteOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
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

    // MARK: - Daily Log Section

    private var dailyLogSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S LOG")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text(Date().displayString)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
                Spacer()

                // Completion badge
                HStack(spacing: 4) {
                    Text("\(viewModel.completionCount)/3")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(completionColor)
                    Image(systemName: viewModel.completionCount == 3 ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(completionColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(completionColor.opacity(0.1))
                .clipShape(Capsule())
            }

            // Section Cards
            logSectionCard(
                title: "Training",
                icon: "figure.run",
                color: ColorTheme.training,
                gradient: ColorTheme.trainingGradient,
                isCompleted: viewModel.hasTraining,
                subtitle: trainingSubtitle
            ) {
                HapticManager.impact(.medium)
                viewModel.showTrainingLog = true
            }

            logSectionCard(
                title: "Nutrition",
                icon: "leaf.fill",
                color: ColorTheme.nutrition,
                gradient: ColorTheme.nutritionGradient,
                isCompleted: viewModel.hasNutrition,
                subtitle: nutritionSubtitle
            ) {
                HapticManager.impact(.medium)
                viewModel.showNutritionLog = true
            }

            logSectionCard(
                title: "Sleep",
                icon: "moon.zzz.fill",
                color: ColorTheme.sleep,
                gradient: ColorTheme.sleepGradient,
                isCompleted: viewModel.hasSleep,
                subtitle: sleepSubtitle
            ) {
                HapticManager.impact(.medium)
                viewModel.showSleepLog = true
            }
        }
        .scaleEffect(heroAppeared ? 1 : 0.96)
        .opacity(heroAppeared ? 1 : 0)
    }

    private var completionColor: Color {
        switch viewModel.completionCount {
        case 3: return Color(hex: "22C55E")
        case 2: return ColorTheme.accent
        case 1: return ColorTheme.training
        default: return ColorTheme.tertiaryText(colorScheme)
        }
    }

    private var trainingSubtitle: String {
        if let t = viewModel.todayTraining {
            return "\(t.sessionCount) session\(t.sessionCount == 1 ? "" : "s") - \(t.totalDuration)min"
        }
        return "Log your training session"
    }

    private var nutritionSubtitle: String {
        if let n = viewModel.todayNutrition {
            return "\(n.mealsLogged) meals logged"
        }
        return "Track your meals"
    }

    private var sleepSubtitle: String {
        if let s = viewModel.todaySleep {
            return "\(s.durationFormatted) sleep"
        }
        return "Record your sleep"
    }

    private func logSectionCard(
        title: String,
        icon: String,
        color: Color,
        gradient: LinearGradient,
        isCompleted: Bool,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isCompleted ? AnyShapeStyle(gradient) : AnyShapeStyle(color.opacity(0.12)))
                        .frame(width: 44, height: 44)

                    Image(systemName: isCompleted ? "checkmark" : icon)
                        .font(.system(size: isCompleted ? 16 : 18, weight: .bold))
                        .foregroundColor(isCompleted ? .white : color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(isCompleted ? color : ColorTheme.tertiaryText(colorScheme))
                        .lineLimit(1)
                }

                Spacer()

                // Status
                if isCompleted {
                    Text("DONE")
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isCompleted ? color.opacity(0.2) : ColorTheme.separator(colorScheme),
                        lineWidth: 1
                    )
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(LogCardButtonStyle())
    }

    // MARK: - Progress Tracker

    private var progressTracker: some View {
        VStack(spacing: 10) {
            HStack {
                Text("DAILY PROGRESS")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(viewModel.completionCount) of 3")
                    .font(.system(size: 12, weight: .bold).width(.condensed))
                    .foregroundColor(completionColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ColorTheme.elevatedBackground(colorScheme))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: progressGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geo.size.width * CGFloat(viewModel.completionCount) / 3.0),
                            height: 8
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.completionCount)
                }
            }
            .frame(height: 8)

            // Section indicators
            HStack(spacing: 0) {
                progressDot(label: "Training", color: ColorTheme.training, done: viewModel.hasTraining)
                Spacer()
                progressDot(label: "Nutrition", color: ColorTheme.nutrition, done: viewModel.hasNutrition)
                Spacer()
                progressDot(label: "Sleep", color: ColorTheme.sleep, done: viewModel.hasSleep)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var progressGradientColors: [Color] {
        switch viewModel.completionCount {
        case 3: return [ColorTheme.accent, Color(hex: "22C55E")]
        case 2: return [ColorTheme.accent, ColorTheme.accent]
        case 1: return [ColorTheme.training, ColorTheme.training]
        default: return [ColorTheme.tertiaryText(colorScheme)]
        }
    }

    private func progressDot(label: String, color: Color, done: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(done ? color : ColorTheme.tertiaryText(colorScheme))
            Text(label)
                .font(.system(size: 10, weight: .semibold).width(.condensed))
                .foregroundColor(done ? color : ColorTheme.tertiaryText(colorScheme))
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 12) {
            streakCard(
                value: viewModel.streak?.currentStreak ?? 0,
                label: "Current",
                icon: "flame.fill",
                gradient: [Color(hex: "F97316"), Color(hex: "EF4444")]
            )
            streakCard(
                value: viewModel.streak?.longestStreak ?? 0,
                label: "Best",
                icon: "trophy.fill",
                gradient: [Color(hex: "EAB308"), Color(hex: "F59E0B")]
            )
        }
    }

    private func streakCard(value: Int, label: String, icon: String, gradient: [Color]) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("\(label) streak")
                    .font(.system(size: 10, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    // MARK: - Compact Breathe Card

    private var compactBreatheCard: some View {
        Button {
            HapticManager.impact(.medium)
            showBreathing = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(hex: "3B82F6").opacity(0.25), radius: 8, x: 0, y: 4)

                    Image(systemName: "wind")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Breathe")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("2-minute mental reset")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Text("START")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(Color(hex: "3B82F6"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "3B82F6").opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(hex: "3B82F6").opacity(0.1), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Coach Promo

    private var aiCoachPromo: some View {
        AIReportPromoCard(style: .home) {
            showSubscription = true
        }
    }
}

// MARK: - Button Styles

struct HeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct LogCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let switchToAICoachTab = Notification.Name("switchToAICoachTab")
}
