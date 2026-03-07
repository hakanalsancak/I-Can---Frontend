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
                    VStack(spacing: 20) {
                        if SubscriptionService.shared.isPremium {
                            premiumGenerateSection
                        } else {
                            lockedHeroSection
                        }

                        if SubscriptionService.shared.isPremium {
                            if viewModel.isLoading {
                                LoadingView(message: "Loading reports...")
                                    .frame(height: 160)
                            } else if viewModel.reports.isEmpty {
                                premiumEmptyState
                            } else {
                                reportsList
                            }
                        } else {
                            featureShowcase
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(Typography.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                if SubscriptionService.shared.isPremium {
                    await viewModel.loadReports()
                }
            }
            .onChange(of: viewModel.selectedType) { _, _ in
                if SubscriptionService.shared.isPremium {
                    Task { await viewModel.loadReports() }
                }
            }
            .sheet(item: $viewModel.selectedReport) { report in
                ReportDetailView(report: report)
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                SubscriptionView()
            }
        }
    }

    // MARK: - Premium Generate Section

    private var premiumGenerateSection: some View {
        VStack(spacing: 16) {
            typePicker

            Button {
                HapticManager.impact(.medium)
                Task { await viewModel.generateReport() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(viewModel.isGenerating ? "Analyzing..." : "Generate \(viewModel.selectedType.capitalized) Report")
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
                .shadow(color: Color(hex: "7C3AED").opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .disabled(viewModel.isGenerating)
        }
    }

    private var typePicker: some View {
        HStack(spacing: 8) {
            ForEach(["weekly", "monthly", "yearly"], id: \.self) { type in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedType = type
                    }
                } label: {
                    Text(type.capitalized)
                        .font(Typography.subheadline)
                        .foregroundColor(viewModel.selectedType == type ? .white : ColorTheme.primaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedType == type
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                              )
                            : AnyShapeStyle(ColorTheme.cardBackground(colorScheme))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                }
            }
        }
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
                Text("1 month free, then $9.99/month")
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
                icon: "chart.bar.fill",
                iconColors: ["7C3AED", "4F46E5"],
                title: "Weekly Reports",
                description: "Detailed analysis of your training patterns, mental state, and performance trends every week."
            )

            featureCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColors: ["8B5CF6", "6D28D9"],
                title: "Monthly Deep Dives",
                description: "Comprehensive monthly reviews covering strengths, areas to improve, and consistency tracking."
            )

            featureCard(
                icon: "star.fill",
                iconColors: ["EAB308", "D97706"],
                title: "Yearly Performance Review",
                description: "Your complete annual athletic journey with long-term growth analysis and milestone tracking."
            )

            featureCard(
                icon: "target",
                iconColors: ["22C55E", "16A34A"],
                title: "Goal-Based Coaching",
                description: "AI connects your daily entries to your goals and provides actionable recommendations."
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

    // MARK: - Reports List (Premium)

    private var reportsList: some View {
        VStack(spacing: 12) {
            Text("YOUR REPORTS")
                .sectionHeader(colorScheme)

            ForEach(viewModel.reports) { report in
                Button {
                    Task { await viewModel.loadReportDetail(report) }
                } label: {
                    reportRow(report)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reportRow(_ report: AIReport) -> some View {
        HStack(spacing: 14) {
            Image(systemName: report.reportIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(report.reportTypeDisplay)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let start = Date.fromAPIString(report.periodStart),
                   let end = Date.fromAPIString(report.periodEnd) {
                    Text("\(start.shortDisplayString) – \(end.shortDisplayString)")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var premiumEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "4F46E5")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Ready to Analyze")
                .font(Typography.title3)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text("Select a report type above and generate\nyour first AI coaching report")
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
