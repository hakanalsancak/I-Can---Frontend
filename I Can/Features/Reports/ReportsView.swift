import SwiftUI
import Combine

struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var showSubscription = false
    @State private var showSavedReports = false
    @State private var now = Date()
    @State private var selectedType: ReportType = .weekly
    @Environment(\.colorScheme) private var colorScheme

    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum ReportType: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        var id: String { rawValue }

        var key: String { rawValue.lowercased() }
        var accent: Color { self == .weekly ? Color(hex: "8B5CF6") : Color(hex: "2563EB") }
        var gradient: [Color] {
            self == .weekly
                ? [Color(hex: "7C3AED"), Color(hex: "4F46E5")]
                : [Color(hex: "2563EB"), Color(hex: "1D4ED8")]
        }
        var icon: String {
            self == .weekly ? "chart.bar.fill" : "chart.line.uptrend.xyaxis"
        }
        var periodLabel: String { self == .weekly ? "week" : "month" }
        var unlockCopy: String {
            self == .weekly ? "Monday at 8pm. That\u{2019}s when the week is graded."
                            : "1st of the month. That\u{2019}s when the verdict drops."
        }
    }

    private var userName: String {
        AuthService.shared.currentUser?.fullName?.components(separatedBy: " ").first ?? "Athlete"
    }

    private var currentPeriod: PeriodInfo? {
        switch selectedType {
        case .weekly: return viewModel.periodStatus?.weekly
        case .monthly: return viewModel.periodStatus?.monthly
        }
    }

    private var hero: AIReport? {
        selectedType == .weekly ? viewModel.weeklyHero : viewModel.monthlyHero
    }

    private var recent: [AIReport] {
        viewModel.recentScores(for: selectedType.key, limit: 4)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        typeSegmentedControl

                        if SubscriptionService.shared.isPremium {
                            premiumContent
                        } else {
                            lockedPitch
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                if SubscriptionService.shared.isPremium {
                    Task { await viewModel.loadAll() }
                }
            }
            .refreshable {
                if SubscriptionService.shared.isPremium {
                    await viewModel.loadAll()
                }
            }
            .sheet(item: $viewModel.selectedReport) { report in
                ReportDetailView(report: report)
            }
            .sheet(isPresented: $showSubscription, onDismiss: {
                Task { try? await SubscriptionService.shared.checkStatus() }
            }) {
                SubscriptionView()
            }
            .sheet(isPresented: $viewModel.showPaywall, onDismiss: {
                Task { try? await SubscriptionService.shared.checkStatus() }
            }) {
                SubscriptionView()
            }
            .sheet(isPresented: $showSavedReports) {
                SavedReportsView(
                    weeklyReports: Array(viewModel.weeklyReports.dropFirst()),
                    monthlyReports: Array(viewModel.monthlyReports.dropFirst())
                ) { report in
                    showSavedReports = false
                    await viewModel.loadReportDetail(report)
                }
            }
            .onReceive(countdownTimer) { _ in
                now = Date()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openReport)) { note in
                guard let id = note.userInfo?["reportId"] as? String else { return }
                if let type = note.userInfo?["reportType"] as? String {
                    selectedType = type == "monthly" ? .monthly : .weekly
                }
                Task { await viewModel.openReport(byId: id) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Reports")
                .font(.system(size: 28, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Spacer()
            if SubscriptionService.shared.isPremium {
                Button {
                    HapticManager.selection()
                    showSavedReports = true
                } label: {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .frame(width: 38, height: 38)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Segmented Control

    private var typeSegmentedControl: some View {
        Picker("Type", selection: $selectedType) {
            ForEach(ReportType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Premium Content

    @ViewBuilder
    private var premiumContent: some View {
        VStack(spacing: 18) {
            if let hero {
                heroCard(hero)
            } else if viewModel.isLoading {
                heroPlaceholder
            } else {
                heroEmpty
            }

            if let period = currentPeriod, !period.reportReady {
                inProgressCard(period: period)
            }

            if recent.count > 1 {
                recentStrip
            }

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
    }

    // MARK: - Hero Card

    private func heroCard(_ report: AIReport) -> some View {
        Button {
            HapticManager.selection()
            Task { await viewModel.loadReportDetail(report) }
        } label: {
            VStack(spacing: 18) {
                HStack {
                    Text(selectedType == .weekly
                         ? report.weekLabel.uppercased()
                         : report.monthLabel.uppercased())
                        .font(.system(size: 12, weight: .heavy).width(.condensed))
                        .tracking(1.2)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Spacer()
                    Text(report.dateRangeDisplay)
                        .font(.system(size: 12, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }

                HStack(alignment: .center, spacing: 22) {
                    heroScoreRing(report: report)

                    VStack(alignment: .leading, spacing: 8) {
                        if let prev = report.content?.prevOverallScore,
                           let score = report.content?.overallScore {
                            heroDeltaPill(score: score, prev: prev)
                        }
                        Text(report.content?.headline ?? heroFallbackHeadline(report: report))
                            .font(.system(size: 16, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .heavy))
                    Text("Open Report")
                        .font(.system(size: 14, weight: .heavy).width(.condensed))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(LinearGradient(colors: selectedType.gradient, startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(18)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func heroScoreRing(report: AIReport) -> some View {
        let score = report.content?.overallScore
        let fraction = CGFloat(min(max(score ?? 0, 0), 100)) / 100.0
        return ZStack {
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round))
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(LinearGradient(colors: selectedType.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.map { "\($0)" } ?? "—")
                    .font(.system(size: 36, weight: .heavy, design: .rounded).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .monospacedDigit()
                Text(report.content?.letterGrade ?? "")
                    .font(.system(size: 12, weight: .heavy).width(.condensed))
                    .foregroundColor(selectedType.accent)
            }
        }
        .frame(width: 110, height: 110)
    }

    private func heroDeltaPill(score: Int, prev: Int) -> some View {
        let diff = score - prev
        let color = diff >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444")
        return HStack(spacing: 4) {
            Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 10, weight: .heavy))
            Text("\(diff >= 0 ? "+" : "")\(diff) vs last \(selectedType.periodLabel)")
                .font(.system(size: 11, weight: .heavy).width(.condensed))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func heroFallbackHeadline(report: AIReport) -> String {
        report.content?.summary?.components(separatedBy: ". ").first.map { $0 + "." }
            ?? "Tap to open your report."
    }

    private var heroPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(ColorTheme.cardBackground(colorScheme))
            .frame(height: 220)
            .shimmering()
    }

    private var heroEmpty: some View {
        VStack(spacing: 10) {
            Image(systemName: selectedType.icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(selectedType.accent)
            Text("No \(selectedType.rawValue.lowercased()) reports yet.")
                .font(.system(size: 16, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text(selectedType.unlockCopy)
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    // MARK: - In Progress Card

    private func inProgressCard(period: PeriodInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS \(selectedType.rawValue.uppercased()) SO FAR")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .tracking(1.2)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text(period.dateRangeDisplay)
                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: period.isEligible
                                            ? [Color(hex: "22C55E"), Color(hex: "16A34A")]
                                            : selectedType.gradient,
                                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(period.progressFraction))
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(period.entryCount) / \(period.requiredEntries) entries")
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(countdownText(for: period))
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                }
                .foregroundColor(selectedType.accent)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Recent Strip

    private var recentStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LAST 4 REPORTS")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .tracking(1.2)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Button {
                    HapticManager.selection()
                    showSavedReports = true
                } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.system(size: 12, weight: .heavy).width(.condensed))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(selectedType.accent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                ForEach(recent) { report in
                    Button {
                        HapticManager.selection()
                        Task { await viewModel.loadReportDetail(report) }
                    } label: {
                        recentChip(report)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func recentChip(_ report: AIReport) -> some View {
        let score = report.content?.overallScore
        return VStack(spacing: 6) {
            Text(score.map { "\($0)" } ?? "—")
                .font(.system(size: 22, weight: .heavy, design: .rounded).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .monospacedDigit()
            Text(shortLabel(for: report))
                .font(.system(size: 11, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(selectedType.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func shortLabel(for report: AIReport) -> String {
        guard let date = Date.fromAPIString(report.periodStart) else { return report.periodStart }
        let fmt = DateFormatter()
        fmt.dateFormat = selectedType == .weekly ? "MMM d" : "MMM"
        return fmt.string(from: date)
    }

    // MARK: - Locked Pitch

    private var lockedPitch: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: selectedType.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                        .shadow(color: selectedType.gradient[0].opacity(0.4), radius: 14, x: 0, y: 8)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                }

                Text("\(userName), you don\u{2019}t get a score without Premium.")
                    .font(.system(size: 22, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 6)

                VStack(alignment: .leading, spacing: 14) {
                    pitchLine(icon: "calendar", title: "Every Monday at 8pm",
                              subtitle: "A 0\u{2013}100 weekly grade. Best day, worst day, one move.")
                    pitchLine(icon: "calendar.badge.clock", title: "Every 1st of the month",
                              subtitle: "Trend, consistency grid, verdict.")
                    pitchLine(icon: "flame.fill", title: "Streaks, deltas, peaks",
                              subtitle: "The dashboard pros use to study tape.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                Button {
                    HapticManager.impact(.medium)
                    showSubscription = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .heavy))
                        Text("Unlock Reports")
                            .font(.system(size: 16, weight: .heavy).width(.condensed))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: selectedType.gradient, startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: selectedType.gradient[0].opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .padding(.top, 4)

                Text("\u{201C}Pros review the tape. So do you.\u{201D}")
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .italic()
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 12, x: 0, y: 6)
        }
    }

    private func pitchLine(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(selectedType.accent)
                .frame(width: 28, height: 28)
                .background(selectedType.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Countdown

    private func countdownText(for period: PeriodInfo) -> String {
        guard let endDate = Date.fromAPIString(period.periodEnd) else {
            return "\(period.daysRemaining)d remaining"
        }
        let calendar = Calendar.current
        guard let deadline = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            return "\(period.daysRemaining)d remaining"
        }
        let remaining = deadline.timeIntervalSince(now)
        guard remaining > 0 else { return "Generating..." }
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        if days > 0 {
            return String(format: "%dd %02dh %02dm", days, hours, minutes)
        } else {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "F59E0B"))
            Text(message)
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Spacer()
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .padding(14)
        .background(Color(hex: "F59E0B").opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Notification deep link

extension Notification.Name {
    static let openReport = Notification.Name("openReport")
}

// MARK: - Shimmer

struct ShimmeringModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.08), location: 0.5),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
            }
            .clipped()
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 2
            }
        }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmeringModifier())
    }
}
