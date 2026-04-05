import SwiftUI
import Combine

struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var showSubscription = false
    @State private var now = Date()
    @Environment(\.colorScheme) private var colorScheme

    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var userName: String {
        AuthService.shared.currentUser?.fullName?.components(separatedBy: " ").first ?? "Athlete"
    }

    private var userSport: String {
        AuthService.shared.currentUser?.sport.capitalized ?? "your sport"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Reports")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if SubscriptionService.shared.isPremium {
                            premiumContent
                        } else {
                            lockedHeroSection
                            previewReportsSection
                            whatYouGetSection
                            lockedCTASection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
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
            .onReceive(countdownTimer) { _ in
                now = Date()
            }
        }
    }

    private func countdownText(for period: PeriodInfo) -> String {
        guard let endDate = Date.fromAPIString(period.periodEnd) else {
            return "\(period.daysRemaining)d remaining"
        }
        // Period end date is a date (no time), report generates at the start of the next day
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
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        } else {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        }
    }

    // MARK: - Premium Content

    private var premiumContent: some View {
        VStack(spacing: 28) {
            reportSection(
                title: "WEEKLY REPORTS",
                icon: "chart.bar.fill",
                iconColor: Color(hex: "8B5CF6"),
                gradient: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                period: viewModel.periodStatus?.weekly,
                reports: viewModel.weeklyReports,
                periodLabel: "week"
            )

            reportSection(
                title: "MONTHLY REPORTS",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color(hex: "2563EB"),
                gradient: [Color(hex: "2563EB"), Color(hex: "1D4ED8")],
                period: viewModel.periodStatus?.monthly,
                reports: viewModel.monthlyReports,
                periodLabel: "month"
            )

            reportSection(
                title: "YEARLY REPORTS",
                icon: "star.fill",
                iconColor: Color(hex: "F59E0B"),
                gradient: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                period: viewModel.periodStatus?.yearly,
                reports: viewModel.yearlyReports,
                periodLabel: "year"
            )

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
    }

    // MARK: - Report Section

    private func reportSection(
        title: String,
        icon: String,
        iconColor: Color,
        gradient: [Color],
        period: PeriodInfo?,
        reports: [AIReport],
        periodLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .sectionHeader(colorScheme)
                Spacer()
            }

            if let period {
                periodProgressCard(period: period, gradient: gradient, periodLabel: periodLabel)
            } else if viewModel.isStatusLoading {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ColorTheme.cardBackground(colorScheme))
                    .frame(height: 100)
                    .shimmering()
            }

            if viewModel.isLoading {
                loadingPlaceholder
            } else if !reports.isEmpty {
                reportCards(reports)
            }
        }
    }

    // MARK: - Period Progress Card

    private func periodProgressCard(period: PeriodInfo, gradient: [Color], periodLabel: String) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(period.dateRangeDisplay)
                            .font(.system(size: 17, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        if period.reportReady {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "22C55E"))
                                Text("Report ready!")
                                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                                    .foregroundColor(Color(hex: "22C55E"))
                            }
                        } else {
                            Text("\(period.daysRemaining) day\(period.daysRemaining == 1 ? "" : "s") remaining")
                                .font(.system(size: 13, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                    }

                    Spacer()

                    if period.reportReady {
                        Button {
                            HapticManager.selection()
                            if let reportId = period.reportId {
                                Task { await viewModel.loadReportDetail(AIReport(
                                    id: reportId,
                                    reportType: periodLabel == "week" ? "weekly" : (periodLabel == "month" ? "monthly" : "yearly"),
                                    periodStart: period.periodStart,
                                    periodEnd: period.periodEnd,
                                    content: nil,
                                    entryCount: nil,
                                    createdAt: nil
                                ))}
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .bold))
                                Text("View")
                                    .font(.system(size: 14, weight: .bold).width(.condensed))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Progress bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(colors: period.isEligible ? [Color(hex: "22C55E"), Color(hex: "16A34A")] : gradient, startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * CGFloat(period.progressFraction), height: 8)
                                .animation(.spring(duration: 0.6), value: period.progressFraction)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(period.entryCount) / \(period.requiredEntries) entries logged")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        Spacer()
                        if !period.reportReady {
                            if period.isEligible {
                                Text("Eligible")
                                    .font(.system(size: 12, weight: .bold).width(.condensed))
                                    .foregroundColor(Color(hex: "22C55E"))
                            } else {
                                Text("Ineligible")
                                    .font(.system(size: 12, weight: .bold).width(.condensed))
                                    .foregroundColor(Color(hex: "EF4444"))
                            }
                        }
                    }
                }

                if !period.reportReady {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(gradient[0])
                        Text(countdownText(for: period))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(gradient[0].opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Report Cards

    private func reportCards(_ reports: [AIReport]) -> some View {
        VStack(spacing: 10) {
            ForEach(reports) { report in
                Button {
                    HapticManager.selection()
                    Task { await viewModel.loadReportDetail(report) }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: report.reportIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(reportIconColor(report.reportType))
                            .frame(width: 32, height: 32)
                            .background(reportIconColor(report.reportType).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.dateRangeDisplay)
                                .font(.system(size: 15, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            HStack(spacing: 8) {
                                if let created = report.createdDateDisplay {
                                    Text("Generated \(created)")
                                        .font(.system(size: 12, weight: .medium).width(.condensed))
                                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                }
                                if let count = report.entryCount {
                                    Text("·  \(count) entries")
                                        .font(.system(size: 12, weight: .medium).width(.condensed))
                                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                    .padding(14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reportIconColor(_ type: String) -> Color {
        switch type {
        case "weekly": return Color(hex: "8B5CF6")
        case "monthly": return Color(hex: "2563EB")
        case "yearly": return Color(hex: "F59E0B")
        default: return ColorTheme.accent
        }
    }

    // MARK: - Loading

    private var loadingPlaceholder: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ColorTheme.cardBackground(colorScheme))
                    .frame(height: 60)
                    .shimmering()
            }
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

    // MARK: - Locked Hero (Non-Premium)

    private var lockedHeroSection: some View {
        VStack(spacing: 20) {
            // Personalized header
            VStack(spacing: 6) {
                Text("\(userName), Your Insights Await")
                    .font(Typography.title2)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text("See what premium athletes get after every training session")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.top, 8)

            Button {
                HapticManager.impact(.medium)
                showSubscription = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                    Text("Unlock All Reports")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(hex: "7C3AED").opacity(0.35), radius: 12, x: 0, y: 6)
            }
        }
    }

    // MARK: - Preview Reports (Blurred Teasers)

    private var previewReportsSection: some View {
        VStack(spacing: 18) {
            // Weekly preview
            lockedReportPreview(
                title: "WEEKLY REPORT",
                icon: "chart.bar.fill",
                iconColor: Color(hex: "8B5CF6"),
                gradient: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                previewContent: weeklyPreviewCard
            )

            // Monthly preview
            lockedReportPreview(
                title: "MONTHLY REPORT",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color(hex: "2563EB"),
                gradient: [Color(hex: "2563EB"), Color(hex: "1D4ED8")],
                previewContent: monthlyPreviewCard
            )

            // Yearly preview
            lockedReportPreview(
                title: "YEARLY REPORT",
                icon: "star.fill",
                iconColor: Color(hex: "F59E0B"),
                gradient: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                previewContent: yearlyPreviewCard
            )
        }
    }

    private func lockedReportPreview(
        title: String,
        icon: String,
        iconColor: Color,
        gradient: [Color],
        previewContent: some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .sectionHeader(colorScheme)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                }
                .foregroundColor(Color(hex: "EAB308"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "EAB308").opacity(0.1))
                .clipShape(Capsule())
            }

            // Blurred preview
            ZStack {
                previewContent
                    .blur(radius: 6)
                    .allowsHitTesting(false)

                // Lock overlay
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: gradient[0].opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Unlock with Premium")
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                HapticManager.impact(.light)
                showSubscription = true
            }
        }
    }

    // MARK: - Preview Card Content (Simulated Report Data)

    private var weeklyPreviewCard: some View {
        VStack(spacing: 12) {
            // Simulated summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Summary")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Your training consistency has been strong this week with 5 out of 7 sessions logged. Focus levels peaked mid-week during tactical sessions.")
                    .font(.system(size: 13, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(3)
            }

            // Simulated metrics row
            HStack(spacing: 0) {
                previewMetric(label: "Focus", value: "8.2", trend: "+0.5")
                previewMetric(label: "Effort", value: "8.7", trend: "+0.3")
                previewMetric(label: "Confidence", value: "7.4", trend: "+1.1")
            }

            // Simulated strengths
            VStack(alignment: .leading, spacing: 6) {
                Text("Key Strengths")
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("Training consistency improving week over week")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("Sleep quality directly boosting performance scores")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var monthlyPreviewCard: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Deep Dive")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("This month showed a significant improvement in mental resilience. Your pre-game focus scores jumped 15% compared to last month.")
                    .font(.system(size: 13, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(3)
            }

            // Simulated progress bars
            VStack(spacing: 8) {
                previewProgressRow(label: "Consistency", value: 0.82, color: Color(hex: "22C55E"))
                previewProgressRow(label: "Mental Growth", value: 0.71, color: Color(hex: "2563EB"))
                previewProgressRow(label: "Performance", value: 0.68, color: Color(hex: "F59E0B"))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Coach Recommendation")
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Focus on visualization exercises before competition days. Your data shows a clear correlation between pre-game mental prep and peak performance.")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var yearlyPreviewCard: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Year in Review")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("A year of dedicated growth. You logged 247 sessions, maintained a 85% consistency rate, and your mental performance scores improved by 32%.")
                    .font(.system(size: 13, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(3)
            }

            // Simulated year stats
            HStack(spacing: 0) {
                previewMetric(label: "Sessions", value: "247", trend: nil)
                previewMetric(label: "Streak", value: "43d", trend: nil)
                previewMetric(label: "Growth", value: "+32%", trend: nil)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func previewMetric(label: String, value: String, trend: String?) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            if let trend {
                Text(trend)
                    .font(.system(size: 12, weight: .bold).width(.condensed))
                    .foregroundColor(Color(hex: "22C55E"))
            }
            Text(label)
                .font(.system(size: 12, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private func previewProgressRow(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 13, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * value, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - What You Get Section

    private var whatYouGetSection: some View {
        VStack(spacing: 14) {
            Text("HOW AI REPORTS WORK")
                .sectionHeader(colorScheme)

            VStack(spacing: 0) {
                stepRow(
                    number: "1",
                    icon: "pencil.and.list.clipboard",
                    title: "Log Your Training",
                    description: "Record your daily sessions, nutrition, and sleep",
                    color: Color(hex: "F97316"),
                    isLast: false
                )
                stepRow(
                    number: "2",
                    icon: "brain.head.profile",
                    title: "AI Analyzes Patterns",
                    description: "Your coach finds trends across all your data",
                    color: Color(hex: "8B5CF6"),
                    isLast: false
                )
                stepRow(
                    number: "3",
                    icon: "doc.text.magnifyingglass",
                    title: "Get Actionable Insights",
                    description: "Receive personalized reports with specific coaching",
                    color: Color(hex: "22C55E"),
                    isLast: true
                )
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
    }

    private func stepRow(number: String, icon: String, title: String, description: String, color: Color, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                    Text(number)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text(description)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 2)

                Spacer()
            }
            .padding(.vertical, 12)

            if !isLast {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(ColorTheme.separator(colorScheme))
                        .frame(width: 1, height: 1)
                        .padding(.leading, 16)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Bottom CTA

    private var lockedCTASection: some View {
        VStack(spacing: 14) {
            Text("Your entries are building up. Unlock AI reports to see what your data reveals about your \(userSport) performance.")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button {
                HapticManager.impact(.medium)
                showSubscription = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Get Premium")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "EAB308"), Color(hex: "D97706")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(hex: "EAB308").opacity(0.35), radius: 12, x: 0, y: 6)
            }
        }
    }
}

// MARK: - Shimmer Modifier

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
