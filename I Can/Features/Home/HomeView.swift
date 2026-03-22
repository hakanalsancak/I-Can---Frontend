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

    @State private var showEntryDetail = false
    @State private var editingEntry = false
    @State private var heroAppeared = false
    @State private var showProfile = false
    @State private var profileImage: UIImage? = nil
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

                        heroEntryCard

                        streakSection

                        breatheSection

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
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    private func loadProfileImage() {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = dir.appendingPathComponent("profile_photo_\(userId).jpg")
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return }
        profileImage = image
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
                .font(.system(size: 20, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(quoteOpacity)
                .id(currentQuoteIndex)
                .frame(minHeight: 52)

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
                .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
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

    // MARK: - Hero Entry Card

    private var heroEntryCard: some View {
        Button {
            HapticManager.impact(.medium)
            if viewModel.hasLoggedToday {
                showEntryDetail = true
            } else {
                viewModel.showDailyEntry = true
            }
        } label: {
            if viewModel.hasLoggedToday {
                loggedHero
            } else {
                notLoggedHero
            }
        }
        .buttonStyle(HeroButtonStyle())
        .scaleEffect(heroAppeared ? 1 : 0.96)
        .opacity(heroAppeared ? 1 : 0)
    }

    private var notLoggedHero: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "F97316"))
                            .frame(width: 8, height: 8)
                        Text("NOT LOGGED")
                            .font(.system(size: 11, weight: .heavy).width(.condensed))
                            .foregroundColor(Color(hex: "F97316"))
                    }

                    Text("Today's\nPerformance")
                        .font(.system(size: 24, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .lineSpacing(2)

                    Text("Track focus, effort & confidence")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .padding(.top, 2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(ColorTheme.accentGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: ColorTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)

                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                metricPreview(icon: "scope", label: "Focus", color: Color(hex: "3B82F6"))
                metricDivider
                metricPreview(icon: "bolt.fill", label: "Effort", color: Color(hex: "F97316"))
                metricDivider
                metricPreview(icon: "shield.fill", label: "Confidence", color: Color(hex: "8B5CF6"))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)

            HStack(spacing: 5) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Under 2 minutes")
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
            }
            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            .padding(.bottom, 14)
        }
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.accent.opacity(colorScheme == .dark ? 0.08 : 0.12), radius: 16, x: 0, y: 6)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(ColorTheme.separator(colorScheme))
            .frame(width: 1, height: 28)
    }

    private func metricPreview(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 13, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private var loggedHero: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("LOGGED TODAY")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .foregroundColor(Color(hex: "22C55E"))
                }

                Text("Today's\nReflection")
                    .font(.system(size: 24, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .lineSpacing(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)

            if let entry = viewModel.todayEntry {
                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                loggedHeroMetrics(entry: entry)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
            }

            HStack(spacing: 5) {
                Image(systemName: "pencil")
                    .font(.system(size: 10, weight: .semibold))
                Text("Tap to view or update")
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
            }
            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            .padding(.bottom, 14)
        }
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(hex: "22C55E").opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color(hex: "22C55E").opacity(colorScheme == .dark ? 0.06 : 0.1), radius: 16, x: 0, y: 6)
    }

    @ViewBuilder
    private func loggedHeroMetrics(entry: DailyEntry) -> some View {
        if let r = entry.responses {
            switch entry.activityType {
            case "training":
                VStack(spacing: 10) {
                    if let worked = r.workedOn, !worked.isEmpty {
                        heroChipRow(chips: worked)
                    }
                    if let skill = r.skillImproved, !skill.isEmpty {
                        heroMetricPill(label: "Improved", value: skill, color: Color(hex: "22C55E"))
                    } else if let focus = r.focusLabel {
                        heroMetricPill(label: "Focus", value: focus, color: Color(hex: "3B82F6"))
                    }
                }
            case "game":
                VStack(spacing: 10) {
                    if let stats = r.gameStats, !stats.isEmpty {
                        let topStats = stats.filter { $0.value > 0 }.prefix(3)
                        if !topStats.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(Array(topStats), id: \.key) { key, value in
                                    heroMetricPill(
                                        label: key.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized.trimmingCharacters(in: .whitespaces),
                                        value: "\(value)",
                                        color: Color(hex: "22C55E")
                                    )
                                }
                            }
                        }
                    } else if let strongest = r.strongestAreas, !strongest.isEmpty {
                        heroChipRow(chips: strongest)
                    }
                }
            case "rest_day":
                VStack(spacing: 10) {
                    if let activities = r.recoveryActivities, !activities.isEmpty {
                        heroChipRow(chips: activities)
                    } else if let activities = r.restActivities, !activities.isEmpty {
                        heroChipRow(chips: activities)
                    }
                    if let study = r.sportStudy, !study.isEmpty, study != "No" {
                        heroMetricPill(label: "Sport Study", value: study, color: Color(hex: "3B82F6"))
                    }
                }
            default:
                numericMetricsRow(entry: entry)
            }
        } else {
            numericMetricsRow(entry: entry)
        }
    }

    private func heroMetricPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text(value)
                .font(.system(size: 13, weight: .bold).width(.condensed))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func heroChipRow(chips: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 11, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
    }

    private func numericMetricsRow(entry: DailyEntry) -> some View {
        HStack(spacing: 0) {
            ratingColumn(label: "Focus", value: entry.focusRating, color: Color(hex: "3B82F6"))
            ratingColumn(label: "Effort", value: entry.effortRating, color: Color(hex: "F97316"))
            ratingColumn(label: "Confidence", value: entry.confidenceRating, color: Color(hex: "8B5CF6"))
        }
    }

    private func ratingColumn(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(ratingColor(value))

            HStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < value ? color : color.opacity(0.12))
                        .frame(height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)

            Text(label)
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .textCase(.uppercase)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("\(label) streak")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - AI Coach Promo

    private var aiCoachPromo: some View {
        AIReportPromoCard(style: .home) {
            showSubscription = true
        }
    }

    // MARK: - Breathe Section

    private var breatheSection: some View {
        Button {
            HapticManager.impact(.medium)
            showBreathing = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color(hex: "3B82F6").opacity(0.35), radius: 12, x: 0, y: 6)

                    Image(systemName: "wind")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 6) {
                    Text("Breathe")
                        .font(.system(size: 20, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("2-minute mental reset")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Text("START")
                    .font(.system(size: 13, weight: .heavy).width(.condensed))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(hex: "3B82F6").opacity(0.12), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero Button Style

struct HeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let switchToAICoachTab = Notification.Name("switchToAICoachTab")
}
