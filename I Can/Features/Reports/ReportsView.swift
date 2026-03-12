import SwiftUI

struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var showSubscription = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("AI Coach")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if SubscriptionService.shared.isPremium {
                            premiumContent
                        } else {
                            lockedHeroSection
                            featureShowcase
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                if SubscriptionService.shared.isPremium {
                    await viewModel.loadAll()
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
                        if !period.reportReady && period.isEligible {
                            Text("Eligible")
                                .font(.system(size: 12, weight: .bold).width(.condensed))
                                .foregroundColor(Color(hex: "22C55E"))
                        }
                    }
                }

                if !period.reportReady {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Report generates at end of \(periodLabel)")
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                    }
                    .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.8))
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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "7C3AED").opacity(0.15), Color(hex: "4F46E5").opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6"), Color(hex: "4F46E5")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Your AI Performance Coach")
                    .font(Typography.title2)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text("Get personalized coaching insights\nfrom your daily entries")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                HapticManager.impact(.medium)
                showSubscription = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                    Text("Start Free Trial")
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

            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "EAB308"))
                Text("1 month free trial included")
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    // MARK: - Feature Showcase (Non-Premium)

    private var featureShowcase: some View {
        VStack(spacing: 12) {
            Text("WHAT YOU'LL GET")
                .sectionHeader(colorScheme)

            featureCard(
                icon: "sparkles",
                iconColors: ["42AAB1", "358A90"],
                title: "Daily Log Insights",
                description: "Get a personalized AI coaching insight every time you submit your daily performance log."
            )

            featureCard(
                icon: "chart.bar.fill",
                iconColors: ["7C3AED", "4F46E5"],
                title: "Weekly Reports",
                description: "Detailed analysis of your training patterns, mental state, and performance trends every week."
            )

            featureCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColors: ["2563EB", "1D4ED8"],
                title: "Monthly Deep Dives",
                description: "Comprehensive monthly reviews covering strengths, areas to improve, and consistency tracking."
            )

            featureCard(
                icon: "star.fill",
                iconColors: ["F59E0B", "D97706"],
                title: "Yearly Reviews",
                description: "Full year performance analysis covering your growth, patterns, and transformation over time."
            )

            featureCard(
                icon: "target",
                iconColors: ["22C55E", "16A34A"],
                title: "Goal-Based Coaching",
                description: "AI analyzes your daily entries and provides actionable coaching recommendations."
            )

            featureCard(
                icon: "brain",
                iconColors: ["F97316", "EA580C"],
                title: "Mental Pattern Analysis",
                description: "Uncover patterns in your focus, confidence, and effort to build a stronger mental game."
            )
        }
    }

    private func featureCard(icon: String, iconColors: [String], title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: iconColors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(description)
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
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
