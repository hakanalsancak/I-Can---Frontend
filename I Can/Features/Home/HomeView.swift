import SwiftUI
import Combine

struct HomeView: View {
    @Bindable private var viewModel = HomeViewModel.shared
    @Bindable private var community = CommunityCountService.shared
    @Binding var selectedTab: Int
    @State private var showBreathing = false
    @State private var showProfile = false
    @State private var profileImage: UIImage? = nil
    @State private var heroAppeared = false
    @State private var joinPulse = false
    @State private var displayedCount: Int = CommunityCountService.shared.count
    @State private var showJoinedAlert = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    private let instagramURL = URL(string: "https://www.instagram.com/ican_app/")!

    var body: some View {
        NavigationStack {
            mainContent
                .background(ColorTheme.background(colorScheme).ignoresSafeArea())
                .navigationBarHidden(true)
                .refreshable { await viewModel.loadData() }
                .task { await viewModel.loadData() }
                .modifier(HomeAlertsModifier(
                    saveError: $viewModel.saveError,
                    showJoinedAlert: $showJoinedAlert
                ))
                .modifier(HomeSheetsModifier(
                    viewModel: viewModel,
                    showBreathing: $showBreathing,
                    showProfile: $showProfile,
                    onProfileDismiss: loadProfileImage
                ))
                .onAppear(perform: handleAppear)
                .onChange(of: community.count) { _, newValue in
                    animateCount(to: newValue)
                }
                .onChange(of: AuthService.shared.currentUser?.id) { _, newId in
                    community.bind(userId: newId)
                    displayedCount = community.count
                    Task { await community.refresh() }
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == 0 {
                        Task { await viewModel.refreshIfNeeded() }
                    }
                }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            homeHeader

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    communityCard
                        .padding(.top, 16)

                    dailyLogSection
                    progressTracker

                    PerformanceDashboardView(
                        weeklyData: viewModel.weeklyAnalytics,
                        monthlyData: viewModel.monthlyAnalytics,
                        previousMonthData: viewModel.previousMonthAnalytics,
                        isLoading: viewModel.isLoadingAnalytics
                    )

                    streakSection
                    compactBreatheCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }

    private func handleAppear() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            heroAppeared = true
        }
        loadProfileImage()
        community.bind(userId: AuthService.shared.currentUser?.id)
        displayedCount = community.count
        Task {
            await community.refresh()
            animateCount(to: community.count)
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

    // MARK: - Community Card

    private var communityCard: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text("I CAN COMMUNITY")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .tracking(1.4)
                    .foregroundColor(ColorTheme.accent)

                Text(formattedCount)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .contentTransition(.numericText(value: Double(displayedCount)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: displayedCount)
                    .scaleEffect(joinPulse ? 1.06 : 1.0)

                Text("athletes strong and growing")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            joinButton

            Divider()
                .background(ColorTheme.separator(colorScheme))
                .padding(.horizontal, 4)

            instagramRow
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [ColorTheme.accent.opacity(0.06), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    private var formattedCount: String {
        displayedCount.formatted(.number)
    }

    private var joinButton: some View {
        Button {
            guard !community.isMember else { return }
            HapticManager.notification(.success)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                joinPulse = true
            }
            showJoinedAlert = true
            Task {
                await community.join()
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    joinPulse = false
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: community.isMember ? "checkmark.seal.fill" : "person.2.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(community.isMember ? "You're part of I Can" : "Join the Community")
                    .font(.system(size: 14, weight: .heavy).width(.condensed))
            }
            .foregroundColor(community.isMember ? ColorTheme.accent : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if community.isMember {
                        ColorTheme.accent.opacity(0.12)
                    } else {
                        LinearGradient(
                            colors: [ColorTheme.accent, ColorTheme.accent.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        community.isMember ? ColorTheme.accent.opacity(0.35) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(LogCardButtonStyle())
        .disabled(community.isMember)
    }

    private var instagramRow: some View {
        Button {
            HapticManager.selection()
            openURL(instagramURL)
        } label: {
            HStack(spacing: 10) {
                Image("InstagramLogo")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Follow on Instagram")
                        .font(.system(size: 13, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("@ican_app")
                        .font(.system(size: 11, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
        }
        .buttonStyle(LogCardButtonStyle())
    }

    private func animateCount(to target: Int) {
        guard target != displayedCount else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            displayedCount = target
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

}

// MARK: - View Modifiers

private struct HomeAlertsModifier: ViewModifier {
    @Binding var saveError: String?
    @Binding var showJoinedAlert: Bool

    func body(content: Content) -> some View {
        content
            .alert("Save Error", isPresented: Binding<Bool>(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
            .alert("Welcome to I Can", isPresented: $showJoinedAlert) {
                Button("Let's go", role: .cancel) {}
            } message: {
                Text("You are now a part of the I Can community.")
            }
    }
}

private struct HomeSheetsModifier: ViewModifier {
    @Bindable var viewModel: HomeViewModel
    @Binding var showBreathing: Bool
    @Binding var showProfile: Bool
    let onProfileDismiss: () -> Void

    func body(content: Content) -> some View {
        content
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
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingExerciseView()
            }
            .sheet(isPresented: $showProfile, onDismiss: onProfileDismiss) {
                ProfileView()
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
    static let switchToReportsTab = Notification.Name("switchToReportsTab")
    static let switchToCommunityTab = Notification.Name("switchToCommunityTab")
    static let openConversation = Notification.Name("openConversation")
}
