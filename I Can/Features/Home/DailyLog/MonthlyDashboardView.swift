import SwiftUI
import Charts

// MARK: - Monthly Performance Score Engine

struct MonthlyScoreEngine {
    let data: AnalyticsResponse
    let previousData: AnalyticsResponse?

    /// Compute a daily performance score (0-100) for a single day
    static func dailyScore(for day: AnalyticsDailyData) -> Int {
        var score = 0.0

        // Training: up to 40 points
        if day.training {
            score += 15 // logged training
            if let dur = day.trainingDuration {
                score += min(Double(dur) / 90.0 * 25.0, 25.0) // up to 25 more for duration
            }
        }

        // Nutrition: up to 30 points
        if day.nutrition, let detail = day.nutritionDetail {
            score += Double(detail.healthScore) * 0.30
        }

        // Sleep: up to 30 points
        if day.sleep, let hours = day.sleepHours {
            if hours >= 7 && hours <= 9 {
                score += 30
            } else if hours >= 6 && hours < 7 {
                score += 20
            } else if hours > 9 && hours <= 10 {
                score += 22
            } else if hours >= 5 {
                score += 10
            } else {
                score += 5
            }
        }

        return min(Int(round(score)), 100)
    }

    /// Average monthly score across logged days only
    var monthlyScore: Int {
        let loggedDays = data.dailyData.filter { $0.training || $0.nutrition || $0.sleep }
        guard !loggedDays.isEmpty else { return 0 }
        let total = loggedDays.reduce(0) { $0 + Self.dailyScore(for: $1) }
        return total / loggedDays.count
    }

    /// Previous month's average score
    var previousMonthScore: Int? {
        guard let prev = previousData else { return nil }
        let loggedDays = prev.dailyData.filter { $0.training || $0.nutrition || $0.sleep }
        guard !loggedDays.isEmpty else { return nil }
        let total = loggedDays.reduce(0) { $0 + Self.dailyScore(for: $1) }
        return total / loggedDays.count
    }

    /// Percentage change from previous month
    var changePercent: Int? {
        guard let prev = previousMonthScore, prev > 0 else { return nil }
        return Int(round(Double(monthlyScore - prev) / Double(prev) * 100))
    }

    /// Best day
    var bestDay: (date: String, score: Int)? {
        let loggedDays = data.dailyData.filter { $0.training || $0.nutrition || $0.sleep }
        guard let best = loggedDays.max(by: { Self.dailyScore(for: $0) < Self.dailyScore(for: $1) }) else { return nil }
        return (best.date, Self.dailyScore(for: best))
    }

    /// Worst day (only among logged days)
    var worstDay: (date: String, score: Int)? {
        let loggedDays = data.dailyData.filter { $0.training || $0.nutrition || $0.sleep }
        guard loggedDays.count > 1,
              let worst = loggedDays.min(by: { Self.dailyScore(for: $0) < Self.dailyScore(for: $1) }) else { return nil }
        return (worst.date, Self.dailyScore(for: worst))
    }

    /// Longest consecutive streak of logged days
    var longestStreak: Int {
        var maxStreak = 0
        var current = 0
        for day in data.dailyData {
            if day.training || day.nutrition || day.sleep {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    /// Highest training duration in a single day
    var highestTrainingDay: (date: String, minutes: Int)? {
        let trainingDays = data.dailyData.compactMap { day -> (String, Int)? in
            guard let dur = day.trainingDuration, dur > 0 else { return nil }
            return (day.date, dur)
        }
        return trainingDays.max(by: { $0.1 < $1.1 })
    }

    /// Best sleep night
    var bestSleepNight: (date: String, hours: Double)? {
        let sleepDays = data.dailyData.compactMap { day -> (String, Double)? in
            guard let hours = day.sleepHours, hours > 0 else { return nil }
            return (day.date, hours)
        }
        // Best = closest to 8h
        return sleepDays.min(by: { abs($0.1 - 8.0) < abs($1.1 - 8.0) })
    }

    /// Days logged count
    var daysLogged: Int {
        data.dailyData.filter { $0.training || $0.nutrition || $0.sleep }.count
    }
}

// MARK: - Monthly Dashboard View

struct MonthlyDashboardView: View {
    let data: AnalyticsResponse
    let previousData: AnalyticsResponse?
    @Environment(\.colorScheme) private var colorScheme

    private var engine: MonthlyScoreEngine {
        MonthlyScoreEngine(data: data, previousData: previousData)
    }

    var body: some View {
        VStack(spacing: 16) {
            monthlyScoreCard
            trendGraph
            consistencyHeatmap
            keyStatsGrid
            if engine.daysLogged >= 3 {
                coachInsights
            }
            bestWorstDays
            personalRecords
        }
    }

    // MARK: - 1. Monthly Score Card

    private var monthlyScoreCard: some View {
        let score = engine.monthlyScore
        let label = scoreLabel(score)
        let color = scoreColor(score)

        return VStack(spacing: 12) {
            HStack {
                Text("MONTHLY PERFORMANCE")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text(monthName)
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
            }

            // Score ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.6), color],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * Double(score) / 100.0)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(Typography.number(42))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 12, weight: .bold).width(.condensed))
                        .foregroundColor(color)
                }
            }
            .frame(width: 120, height: 120)

            // Comparison
            if let change = engine.changePercent {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(abs(change))% \(change >= 0 ? "improvement" : "decline") from last month")
                        .font(.system(size: 12, weight: .semibold).width(.condensed))
                }
                .foregroundColor(change >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((change >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444")).opacity(0.1))
                .clipShape(Capsule())
            }

            // Pillar breakdown
            HStack(spacing: 10) {
                pillarStat(
                    icon: "figure.run",
                    label: "Training",
                    value: "\(data.trainingSessions)",
                    color: ColorTheme.training
                )
                pillarStat(
                    icon: "leaf.fill",
                    label: "Nutrition",
                    value: data.nutritionSummary != nil ? "\(data.nutritionSummary!.avgHealthScore)" : "--",
                    color: ColorTheme.nutrition
                )
                pillarStat(
                    icon: "moon.fill",
                    label: "Sleep",
                    value: data.avgSleepHours != nil ? String(format: "%.1f", data.avgSleepHours!) : "--",
                    color: ColorTheme.sleep
                )
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func pillarStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                Text(value)
                    .font(Typography.number(18))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
            Text(label)
                .font(.system(size: 9, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - 2. Trend Graph

    private var trendGraph: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PERFORMANCE TREND")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(engine.daysLogged) days logged")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
            }

            let chartData: [(day: Int, score: Int, logged: Bool)] = data.dailyData.enumerated().map { i, d in
                let hasData = d.training || d.nutrition || d.sleep
                return (i + 1, hasData ? MonthlyScoreEngine.dailyScore(for: d) : 0, hasData)
            }

            let loggedOnly = chartData.filter { $0.logged }

            Chart {
                ForEach(loggedOnly, id: \.day) { item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(ColorTheme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.accent.opacity(0.25), ColorTheme.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(scoreColor(item.score))
                    .symbolSize(20)
                }
            }
            .chartXScale(domain: 1...max(data.dailyData.count, 28))
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(ColorTheme.separator(colorScheme))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 8, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 8, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - 3. Consistency Heatmap

    private var consistencyHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CONSISTENCY")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                let pct = data.expectedDays > 0 ? Int(round(Double(engine.daysLogged) / Double(data.expectedDays) * 100)) : 0
                Text("\(pct)% logged")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
            }

            // Calendar grid: 7 columns (Mon-Sun)
            let days = data.dailyData
            let firstDate = Date.fromAPIString(data.startDate)
            let startWeekday = firstDate.map { weekdayMondayBased($0) } ?? 0

            // Build grid with leading padding
            let paddedDays: [AnalyticsDailyData?] = Array(repeating: nil, count: startWeekday) + days.map { $0 }
            let rows = (paddedDays.count + 6) / 7

            VStack(spacing: 3) {
                // Day headers
                HStack(spacing: 3) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { label in
                        Text(label)
                            .font(.system(size: 8, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { col in
                            let idx = row * 7 + col
                            if idx < paddedDays.count, let day = paddedDays[idx] {
                                let hasData = day.training || day.nutrition || day.sleep
                                let score = hasData ? MonthlyScoreEngine.dailyScore(for: day) : -1
                                let dayNum = idx - startWeekday + 1
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(score >= 0 ? scoreColor(score) : ColorTheme.separator(colorScheme))
                                    Text("\(dayNum)")
                                        .font(.system(size: 9, weight: .bold).width(.condensed))
                                        .foregroundColor(score >= 0 ? .white : ColorTheme.tertiaryText(colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 0) {
                heatmapLegendItem(label: "Poor", color: Color(hex: "EF4444"))
                heatmapLegendItem(label: "Fair", color: Color(hex: "F59E0B"))
                heatmapLegendItem(label: "Good", color: ColorTheme.accent)
                heatmapLegendItem(label: "Great", color: Color(hex: "22C55E"))
                heatmapLegendItem(label: "Elite", color: Color(hex: "10B981"))
                heatmapLegendItem(label: "None", color: ColorTheme.separator(colorScheme))
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func heatmapLegendItem(label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 7, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 4. Key Stats Grid

    private var keyStatsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KEY METRICS")
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            HStack(spacing: 10) {
                keyMetric(
                    value: formatHours(data.trainingSummary?.totalDuration ?? 0),
                    label: "Total Training",
                    icon: "figure.run",
                    color: ColorTheme.training
                )
                keyMetric(
                    value: data.trainingSummary != nil ? "\(data.trainingSummary!.avgDuration)m" : "--",
                    label: "Avg Session",
                    icon: "timer",
                    color: ColorTheme.training
                )
            }

            HStack(spacing: 10) {
                keyMetric(
                    value: data.nutritionSummary != nil ? "\(data.nutritionSummary!.avgHealthScore)" : "--",
                    label: "Avg Nutrition",
                    icon: "leaf.fill",
                    color: ColorTheme.nutrition
                )
                keyMetric(
                    value: data.avgSleepHours != nil ? String(format: "%.1fh", data.avgSleepHours!) : "--",
                    label: "Avg Sleep",
                    icon: "moon.fill",
                    color: ColorTheme.sleep
                )
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func keyMetric(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Typography.number(18))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(label)
                    .font(.system(size: 9, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(ColorTheme.elevatedBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - 5. Coach Insights

    private var coachInsights: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ColorTheme.accent)
                Text("COACH INSIGHTS")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            ForEach(generateInsights(), id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(ColorTheme.accent)
                        .frame(width: 5, height: 5)
                        .padding(.top, 5)
                    Text(insight)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func generateInsights() -> [String] {
        var insights: [String] = []

        // Consistency
        let logPct = data.expectedDays > 0 ? Double(engine.daysLogged) / Double(data.expectedDays) * 100 : 0
        if logPct >= 80 {
            insights.append("Strong consistency this month. Logging \(Int(logPct))% of days shows real commitment.")
        } else if logPct >= 50 {
            insights.append("You logged \(Int(logPct))% of days. Push for more consistent tracking to see real progress.")
        } else if engine.daysLogged > 0 {
            insights.append("Only \(engine.daysLogged) days logged. Consistent tracking is the foundation of improvement.")
        }

        // Training
        if let summary = data.trainingSummary, summary.totalSessions > 0 {
            if summary.totalSessions >= 20 {
                insights.append("Exceptional training volume with \(summary.totalSessions) sessions. Make sure recovery matches.")
            } else if summary.totalSessions >= 12 {
                insights.append("\(summary.totalSessions) training sessions is solid. Focus on quality over quantity next month.")
            }
        }

        // Sleep
        if let avg = data.avgSleepHours {
            if avg >= 7.5 && avg <= 9 {
                insights.append("Sleep averaging \(String(format: "%.1f", avg))h is in the optimal zone. Keep it up.")
            } else if avg < 7 {
                insights.append("Sleep at \(String(format: "%.1f", avg))h is below optimal. Target 7-9 hours for peak performance.")
            }
        }

        // Comparison
        if let change = engine.changePercent {
            if change > 10 {
                insights.append("Up \(change)% from last month. You're on a great trajectory.")
            } else if change < -10 {
                insights.append("Down \(abs(change))% from last month. Review what changed and reset your routine.")
            }
        }

        return Array(insights.prefix(3))
    }

    // MARK: - 6. Best & Worst Days

    private var bestWorstDays: some View {
        HStack(spacing: 10) {
            if let best = engine.bestDay {
                dayHighlight(
                    title: "BEST DAY",
                    date: best.date,
                    score: best.score,
                    icon: "arrow.up.circle.fill",
                    accentColor: Color(hex: "22C55E")
                )
            }
            if let worst = engine.worstDay {
                dayHighlight(
                    title: "WORST DAY",
                    date: worst.date,
                    score: worst.score,
                    icon: "arrow.down.circle.fill",
                    accentColor: Color(hex: "EF4444")
                )
            }
        }
    }

    private func dayHighlight(title: String, date: String, score: Int, icon: String, accentColor: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 9, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Text("\(score)")
                .font(Typography.number(28))
                .foregroundColor(scoreColor(score))

            Text(scoreLabel(score))
                .font(.system(size: 10, weight: .bold).width(.condensed))
                .foregroundColor(scoreColor(score))

            Text(formatDateLabel(date))
                .font(.system(size: 10, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    // MARK: - 7. Personal Records

    private var personalRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))
                Text("PERSONAL RECORDS")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            VStack(spacing: 8) {
                if engine.longestStreak > 0 {
                    recordRow(
                        icon: "flame.fill",
                        label: "Longest Streak",
                        value: "\(engine.longestStreak) days",
                        color: Color(hex: "F97316")
                    )
                }
                if let best = engine.highestTrainingDay {
                    recordRow(
                        icon: "figure.run",
                        label: "Highest Training Day",
                        value: formatDuration(best.minutes),
                        color: ColorTheme.training
                    )
                }
                if let sleep = engine.bestSleepNight {
                    recordRow(
                        icon: "moon.fill",
                        label: "Best Sleep Night",
                        value: String(format: "%.1fh", sleep.hours),
                        color: ColorTheme.sleep
                    )
                }
                if engine.daysLogged > 0 {
                    recordRow(
                        icon: "calendar",
                        label: "Days Logged",
                        value: "\(engine.daysLogged) / \(data.expectedDays)",
                        color: ColorTheme.accent
                    )
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func recordRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Spacer()
            Text(value)
                .font(Typography.number(14))
                .foregroundColor(color)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Int) -> Color {
        if score >= 86 { return Color(hex: "10B981") }
        if score >= 71 { return Color(hex: "22C55E") }
        if score >= 51 { return ColorTheme.accent }
        if score >= 31 { return Color(hex: "F59E0B") }
        return Color(hex: "EF4444")
    }

    private func scoreLabel(_ score: Int) -> String {
        if score >= 86 { return "Elite" }
        if score >= 71 { return "Great" }
        if score >= 51 { return "Good" }
        if score >= 31 { return "Fair" }
        return "Poor"
    }

    private var monthName: String {
        guard let date = Date.fromAPIString(data.startDate) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formatDateLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatHours(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func formatDuration(_ minutes: Int) -> String {
        formatHours(minutes)
    }

    /// Returns 0-based Monday weekday (0=Mon, 6=Sun)
    private func weekdayMondayBased(_ date: Date) -> Int {
        let wd = Calendar.current.component(.weekday, from: date)
        return wd == 1 ? 6 : wd - 2
    }
}
