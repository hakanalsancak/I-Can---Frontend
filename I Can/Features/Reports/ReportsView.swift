import SwiftUI

struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @State private var showSubscription = false
    @State private var generatingType: String?
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
                    await viewModel.loadReports()
                    await viewModel.checkEligibility()
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

    // MARK: - Premium Content

    private var premiumContent: some View {
        VStack(spacing: 24) {
            weeklySection
            monthlySection

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
    }

    // MARK: - Weekly Section

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "8B5CF6"))
                Text("WEEKLY REPORTS")
                    .sectionHeader(colorScheme)
                Spacer()
            }

            generateCard(
                type: "weekly",
                eligibility: viewModel.weeklyEligibility,
                icon: "chart.bar.fill",
                gradient: [Color(hex: "7C3AED"), Color(hex: "4F46E5")]
            )

            if viewModel.isLoading {
                loadingPlaceholder
            } else if !viewModel.weeklyReports.isEmpty {
                reportCards(viewModel.weeklyReports)
            }
        }
    }

    // MARK: - Monthly Section

    private var monthlySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "2563EB"))
                Text("MONTHLY REPORTS")
                    .sectionHeader(colorScheme)
                Spacer()
            }

            generateCard(
                type: "monthly",
                eligibility: viewModel.monthlyEligibility,
                icon: "chart.line.uptrend.xyaxis",
                gradient: [Color(hex: "2563EB"), Color(hex: "1D4ED8")]
            )

            if viewModel.isLoading {
                loadingPlaceholder
            } else if !viewModel.monthlyReports.isEmpty {
                reportCards(viewModel.monthlyReports)
            }
        }
    }

    // MARK: - Generate Card

    private func generateCard(
        type: String,
        eligibility: GenerateEligibility?,
        icon: String,
        gradient: [Color]
    ) -> some View {
        let canGenerate = eligibility?.canGenerate ?? false
        let isThisGenerating = viewModel.isGenerating && generatingType == type
        let periodLabel = eligibility.flatMap { e -> String? in
            guard let s = e.periodStart, let ed = e.periodEnd,
                  let startD = Date.fromAPIString(s),
                  let endD = Date.fromAPIString(ed) else { return nil }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: startD)) – \(fmt.string(from: endD))"
        }

        return VStack(spacing: 0) {
            Button {
                guard canGenerate, !viewModel.isGenerating else { return }
                HapticManager.impact(.medium)
                generatingType = type
                Task { await viewModel.generateReport(type: type) }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        if isThisGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: canGenerate ? "sparkles" : "lock.fill")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(width: 20)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(isThisGenerating ? "Analyzing Your Data..." : (canGenerate ? "Generate \(type.capitalized) Report" : "Already Generated"))
                            .font(.system(size: 15, weight: .bold).width(.condensed))

                        if let period = periodLabel {
                            Text(period)
                                .font(.system(size: 12, weight: .medium).width(.condensed))
                                .opacity(0.8)
                        }
                    }

                    Spacer()

                    if canGenerate && !isThisGenerating {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: canGenerate ? gradient : [Color(hex: "374151"), Color(hex: "1F2937")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: (canGenerate ? gradient[0] : .clear).opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canGenerate || viewModel.isGenerating)

            if !canGenerate, let reason = eligibility?.reason {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                    Text(reason)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                }
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .padding(.top, 8)
                .padding(.horizontal, 4)

                if let required = eligibility?.required, let current = eligibility?.current {
                    progressBar(current: current, required: required, gradient: gradient)
                        .padding(.top, 6)
                }
            }
        }
    }

    private func progressBar(current: Int, required: Int, gradient: [Color]) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorTheme.cardBackground(colorScheme))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(CGFloat(current) / CGFloat(required), 1.0), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(current)/\(required) entries logged")
                    .font(.system(size: 11, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
            }
        }
        .padding(.horizontal, 4)
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.dateRangeDisplay)
                                .font(.system(size: 15, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            if let created = report.createdDateDisplay {
                                Text("Generated \(created)")
                                    .font(.system(size: 12, weight: .medium).width(.condensed))
                                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
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
