import SwiftUI
import Charts

// MARK: - Chart Data

struct DailyChartData: Identifiable {
    let id = UUID()
    let date: String
    let dayLabel: String
    let completion: Int
    let training: Bool
    let nutrition: Bool
    let sleep: Bool
    let sleepHours: Double?
}

// MARK: - Performance Dashboard

struct PerformanceDashboardView: View {
    let weeklyData: AnalyticsResponse?
    let monthlyData: AnalyticsResponse?
    let previousMonthData: AnalyticsResponse?
    let isLoading: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPeriod = 1 // 0 = daily, 1 = week, 2 = month
    @State private var selectedDayIndex = currentWeekdayIndex()

    // Weekly sections now always use weeklyData directly
    // Monthly has its own dedicated MonthlyDashboardView

    /// Returns the selected day's data when in daily mode
    private var selectedDayData: AnalyticsDailyData? {
        guard selectedPeriod == 0, let data = weeklyData else { return nil }
        guard selectedDayIndex < data.dailyData.count else { return nil }
        return data.dailyData[selectedDayIndex]
    }

    /// Returns today's weekday index (0 = Monday, 6 = Sunday)
    private static func currentWeekdayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar: 1=Sun, 2=Mon, ... 7=Sat -> convert to 0=Mon, 6=Sun
        return weekday == 1 ? 6 : weekday - 2
    }

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PERFORMANCE")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text("Dashboard")
                        .font(.system(size: 22, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                Spacer()

                // Period Toggle
                HStack(spacing: 0) {
                    periodTab("Day", index: 0)
                    periodTab("Week", index: 1)
                    periodTab("Month", index: 2)
                }
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Day Selector (only in daily mode)
            if selectedPeriod == 0 {
                daySelectorRow
            }

            if selectedPeriod == 0 {
                // Daily mode - show selected day's data
                if let dayData = selectedDayData {
                    // Overall daily score
                    if dayData.training || dayData.nutrition || dayData.sleep {
                        dailyScoreCard(dayData)
                    }

                    dailyStatsOverview(dayData)

                    if dayData.training, let duration = dayData.trainingDuration {
                        dailyTrainingSection(dayData, duration: duration)
                    }

                    if dayData.nutrition, let detail = dayData.nutritionDetail {
                        dailyNutritionSection(detail)
                    }

                    if dayData.sleep, let hours = dayData.sleepHours {
                        dailySleepSection(hours)
                    }

                    if !dayData.training && !dayData.nutrition && !dayData.sleep {
                        noDataView(message: "No data logged for \(dayLabels[selectedDayIndex])")
                    }
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    noDataView(message: "No data for \(dayLabels[selectedDayIndex])")
                }
            } else if selectedPeriod == 2 {
                // Monthly - premium dashboard
                if let data = monthlyData {
                    MonthlyDashboardView(data: data, previousData: previousMonthData)
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    noDataView(message: "Start logging to see your monthly report")
                }
            } else if let data = weeklyData {
                // Weekly mode
                statsOverview(data)

                if data.trainingSessions > 0, let summary = data.trainingSummary {
                    trainingSection(data, summary: summary)
                }

                if data.nutritionDays > 0, let summary = data.nutritionSummary {
                    nutritionSection(data, summary: summary)
                }

                if data.sleepDays > 0 {
                    sleepChart(data)
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                noDataView(message: "Start logging to see your data")
            }
        }
    }

    // MARK: - No Data

    private func noDataView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Text(message)
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 20)
    }

    // MARK: - Period Tab

    private func periodTab(_ label: String, index: Int) -> some View {
        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPeriod = index
            }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .foregroundColor(selectedPeriod == index ? .white : ColorTheme.secondaryText(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    selectedPeriod == index
                        ? AnyShapeStyle(ColorTheme.accentGradient)
                        : AnyShapeStyle(Color.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Selector

    private var daySelectorRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDayIndex = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayLabels[index])
                            .font(.system(size: 11, weight: .bold).width(.condensed))
                            .foregroundColor(
                                selectedDayIndex == index
                                    ? .white
                                    : ColorTheme.secondaryText(colorScheme)
                            )

                        // Activity dot
                        if let data = weeklyData {
                            if index < data.dailyData.count {
                                let day = data.dailyData[index]
                                Circle()
                                    .fill(dayHasData(day)
                                        ? (selectedDayIndex == index ? Color.white.opacity(0.8) : ColorTheme.accent)
                                        : Color.clear
                                    )
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle().fill(Color.clear).frame(width: 4, height: 4)
                            }
                        } else {
                            Circle().fill(Color.clear).frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedDayIndex == index
                            ? AnyShapeStyle(ColorTheme.accentGradient)
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(ColorTheme.elevatedBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func dayHasData(_ day: AnalyticsDailyData) -> Bool {
        day.training || day.nutrition || day.sleep
    }

    // MARK: - Daily Score Card

    private func dailyScoreCard(_ day: AnalyticsDailyData) -> some View {
        let score = MonthlyScoreEngine.dailyScore(for: day)
        let color = healthScoreColor(score)
        let label = healthScoreLabel(score)

        return HStack(spacing: 14) {
            // Score ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(Typography.number(20))
                    .foregroundColor(color)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("DAILY SCORE")
                    .font(.system(size: 9, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text(label)
                    .font(.system(size: 16, weight: .bold).width(.condensed))
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Daily Stats Overview

    private func dailyStatsOverview(_ day: AnalyticsDailyData) -> some View {
        HStack(spacing: 10) {
            statCard(
                value: day.training ? "\(day.trainingDuration ?? 0)m" : "--",
                label: "Training",
                icon: "figure.run",
                color: ColorTheme.training
            )
            statCard(
                value: day.nutrition ? "\(day.nutritionDetail?.healthScore ?? 0)" : "--",
                label: "Nutrition",
                icon: "leaf.fill",
                color: ColorTheme.nutrition
            )
            statCard(
                value: day.sleepHours != nil ? String(format: "%.1fh", day.sleepHours!) : "--",
                label: "Sleep",
                icon: "moon.fill",
                color: ColorTheme.sleep
            )
        }
    }

    // MARK: - Daily Training Section

    private func dailyTrainingSection(_ day: AnalyticsDailyData, duration: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRAINING")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text(formatDuration(duration))
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.training)
            }

            if let sessions = day.trainingSessions, !sessions.isEmpty {
                ForEach(sessions.indices, id: \.self) { i in
                    let session = sessions[i]
                    HStack(spacing: 10) {
                        Image(systemName: trainingTypeIcon(session.type))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ColorTheme.training)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.type.capitalized)
                                .font(.system(size: 13, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Text("\(session.duration)min  \(session.intensity.capitalized)")
                                .font(.system(size: 11, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }

                        Spacer()

                        Text(intensityBadge(session.intensity))
                            .font(.system(size: 10, weight: .bold).width(.condensed))
                            .foregroundColor(intensityColor(session.intensity))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(intensityColor(session.intensity).opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if i < sessions.count - 1 {
                        Divider()
                            .foregroundColor(ColorTheme.separator(colorScheme))
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Daily Nutrition Section

    private func dailyNutritionSection(_ detail: AnalyticsNutritionDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NUTRITION")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(detail.mealsLogged) meals")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.nutrition)
            }

            HStack(spacing: 16) {
                healthScoreRing(score: detail.healthScore, size: 64, lineWidth: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(healthScoreLabel(detail.healthScore))
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                        .foregroundColor(healthScoreColor(detail.healthScore))
                    Text("\(detail.mealsLogged) meals logged")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func mealIndicator(_ label: String, filled: Bool, color: Color) -> some View {
        VStack(spacing: 3) {
            Circle()
                .fill(filled ? color : ColorTheme.separator(colorScheme))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 8, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
    }

    // MARK: - Daily Sleep Section

    private func dailySleepSection(_ hours: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SLEEP")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text(sleepQualityLabel(hours))
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(sleepQualityColor(hours))
            }

            HStack(spacing: 16) {
                // Hours display
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", hours))
                        .font(Typography.number(36))
                        .foregroundColor(ColorTheme.sleep)
                    Text("hours")
                        .font(.system(size: 11, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .textCase(.uppercase)
                }

                Spacer()

                // Sleep bar visualization
                VStack(alignment: .leading, spacing: 6) {
                    sleepBar(label: "Your Sleep", value: hours, maxValue: 12, color: ColorTheme.sleep)
                    sleepBar(label: "Ideal (7-9h)", value: 8, maxValue: 12, color: ColorTheme.nutrition.opacity(0.4))
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func sleepBar(label: String, value: Double, maxValue: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(4, geo.size.width * CGFloat(min(value, maxValue)) / CGFloat(maxValue)))
            }
            .frame(height: 8)
        }
    }

    private func sleepQualityLabel(_ hours: Double) -> String {
        if hours >= 8 { return "Excellent" }
        if hours >= 7 { return "Good" }
        if hours >= 6 { return "Fair" }
        return "Poor"
    }

    private func sleepQualityColor(_ hours: Double) -> Color {
        if hours >= 7 && hours <= 9 { return ColorTheme.nutrition }
        if hours >= 6 { return ColorTheme.training }
        return Color(hex: "EF4444")
    }

    // MARK: - Stats Overview (Weekly/Monthly)

    private func statsOverview(_ data: AnalyticsResponse) -> some View {
        HStack(spacing: 10) {
            statCard(
                value: "\(data.trainingSessions)",
                label: "Training",
                icon: "figure.run",
                color: ColorTheme.training
            )
            statCard(
                value: "\(data.nutritionDays)",
                label: "Nutrition",
                icon: "leaf.fill",
                color: ColorTheme.nutrition
            )
            statCard(
                value: data.avgSleepHours != nil ? String(format: "%.1f", data.avgSleepHours!) : "--",
                label: "Avg Sleep",
                icon: "moon.fill",
                color: ColorTheme.sleep
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                Text(value)
                    .font(Typography.number(22))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
            Text(label)
                .font(.system(size: 10, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    // MARK: - Training Section (Weekly/Monthly) - Simplified

    private func trainingSection(_ data: AnalyticsResponse, summary: AnalyticsTrainingSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRAINING")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(summary.totalSessions) sessions")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.training)
            }

            // Duration stats
            HStack(spacing: 10) {
                miniStat(
                    value: formatDuration(summary.totalDuration),
                    label: "Total Time",
                    color: ColorTheme.training
                )
                miniStat(
                    value: "\(summary.avgDuration)m",
                    label: "Avg Session",
                    color: ColorTheme.training
                )
            }

            // Duration bar chart - all days in range
            let allDays = allDaysInRange(data)
            let trainingDays = allDays.map { (label: $0.label, duration: $0.data?.trainingDuration ?? 0) }

            Chart(trainingDays, id: \.label) { item in
                BarMark(
                    x: .value("Day", item.label),
                    y: .value("Minutes", item.duration)
                )
                .foregroundStyle(
                    item.duration > 0
                        ? AnyShapeStyle(LinearGradient(
                            colors: [ColorTheme.training, ColorTheme.training.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        : AnyShapeStyle(ColorTheme.separator(colorScheme).opacity(0.3))
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(ColorTheme.separator(colorScheme))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)m")
                            .font(.system(size: 9, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(value.as(String.self) ?? "")
                            .font(.system(size: 9, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }
            .frame(height: 120)

        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Nutrition Section (Weekly/Monthly) - Simplified

    private func nutritionSection(_ data: AnalyticsResponse, summary: AnalyticsNutritionSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("NUTRITION")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(summary.daysLogged) days logged")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.nutrition)
            }

            // Average health score ring
            HStack(spacing: 20) {
                healthScoreRing(score: summary.avgHealthScore, size: 90, lineWidth: 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("AVG HEALTH SCORE")
                        .font(.system(size: 9, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                    Text(healthScoreLabel(summary.avgHealthScore))
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                        .foregroundColor(healthScoreColor(summary.avgHealthScore))

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f", summary.avgMealsPerDay))
                                .font(Typography.number(14))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Text("Meals/Day")
                                .font(.system(size: 8, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                                .textCase(.uppercase)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(summary.daysLogged)")
                                .font(Typography.number(14))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Text("Days")
                                .font(.system(size: 8, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                                .textCase(.uppercase)
                        }
                    }
                }

                Spacer()
            }

            // Daily health scores as mini rings - all days in range
            let allNutritionDays = allDaysInRange(data)

            VStack(alignment: .leading, spacing: 8) {
                Text("DAILY SCORES")
                    .font(.system(size: 9, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                HStack(spacing: 0) {
                    ForEach(allNutritionDays.indices, id: \.self) { i in
                        let day = allNutritionDays[i]
                        VStack(spacing: 4) {
                            if let detail = day.data?.nutritionDetail {
                                healthScoreRing(score: detail.healthScore, size: 38, lineWidth: 4)
                            } else {
                                // Empty placeholder ring
                                ZStack {
                                    Circle()
                                        .stroke(ColorTheme.separator(colorScheme), lineWidth: 4)
                                    Text("--")
                                        .font(.system(size: 10, weight: .medium).width(.condensed))
                                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                                }
                                .frame(width: 38, height: 38)
                            }
                            Text(day.label)
                                .font(.system(size: 9, weight: .medium).width(.condensed))
                                .foregroundColor(
                                    day.data?.nutritionDetail != nil
                                        ? ColorTheme.secondaryText(colorScheme)
                                        : ColorTheme.tertiaryText(colorScheme)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Score legend
            HStack(spacing: 0) {
                scoreLegendItem(label: "Poor", range: "1-30", color: Color(hex: "EF4444"))
                scoreLegendItem(label: "Fair", range: "31-50", color: Color(hex: "F59E0B"))
                scoreLegendItem(label: "Good", range: "51-70", color: ColorTheme.accent)
                scoreLegendItem(label: "Great", range: "71-85", color: Color(hex: "22C55E"))
                scoreLegendItem(label: "Elite", range: "86+", color: Color(hex: "10B981"))
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Sleep Chart (Weekly/Monthly)

    private func sleepChart(_ data: AnalyticsResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SLEEP HOURS")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                if let avg = data.avgSleepHours {
                    Text(String(format: "%.1fh avg", avg))
                        .font(.system(size: 11, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.sleep)
                }
            }

            let allSleepDays = allDaysInRange(data)
            let sleepChartData = allSleepDays.map { (label: $0.label, hours: $0.data?.sleepHours) }

            Chart(sleepChartData.indices, id: \.self) { i in
                let item = sleepChartData[i]
                if let hours = item.hours {
                    LineMark(
                        x: .value("Day", item.label),
                        y: .value("Hours", hours)
                    )
                    .foregroundStyle(ColorTheme.sleep)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Day", item.label),
                        y: .value("Hours", hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.sleep.opacity(0.2), ColorTheme.sleep.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.label),
                        y: .value("Hours", hours)
                    )
                    .foregroundStyle(ColorTheme.sleep)
                    .symbolSize(24)
                }
            }
            .chartYScale(domain: 0...12)
            .chartYAxis {
                AxisMarks(values: [0, 4, 6, 8, 10, 12]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(ColorTheme.separator(colorScheme))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)h")
                            .font(.system(size: 9, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(value.as(String.self) ?? "")
                            .font(.system(size: 9, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
            }
            .frame(height: 140)

            // Ideal range indicator
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ColorTheme.nutrition.opacity(0.3))
                    .frame(width: 16, height: 8)
                Text("7-9h ideal range")
                    .font(.system(size: 10, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Health Score Ring

    private func healthScoreRing(score: Int, size: CGFloat, lineWidth: CGFloat) -> some View {
        let progress = Double(score) / 100.0
        let color = healthScoreColor(score)

        return ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.6), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(Typography.number(size > 60 ? 22 : 12))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Sub-Components

    private func scoreLegendItem(label: String, range: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text(range)
                .font(.system(size: 7, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Typography.number(18))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
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

    // MARK: - Full Range Helpers

    /// Maps dailyData to labeled tuples. Backend already returns all days in range.
    /// Weekly uses day-of-week labels (Mon-Sun), monthly uses date numbers (1, 2, ...).
    private func allDaysInRange(_ data: AnalyticsResponse) -> [(label: String, data: AnalyticsDailyData?)] {
        let isMonthly = data.period == "month"
        return data.dailyData.map { item in
            let label = isMonthly ? dayNumber(item.date) : shortDayLabel(item.date)
            let hasData = item.training || item.nutrition || item.sleep
            return (label, hasData ? item : nil)
        }
    }

    // MARK: - Helpers

    private func shortDayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr.suffix(2).description }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func dayNumber(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr.suffix(2).description }
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func trainingTypeIcon(_ type: String) -> String {
        switch type {
        case "match": return "trophy.fill"
        case "gym": return "dumbbell.fill"
        case "cardio": return "heart.circle.fill"
        case "technical": return "figure.run"
        case "tactical": return "brain.head.profile"
        case "recovery": return "leaf.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    private func intensityColor(_ level: String) -> Color {
        switch level {
        case "low": return Color(hex: "22C55E")
        case "medium": return ColorTheme.accent
        case "high": return Color(hex: "F97316")
        case "max": return Color(hex: "EF4444")
        default: return ColorTheme.secondaryText(colorScheme)
        }
    }

    private func intensityBadge(_ level: String) -> String {
        level.capitalized
    }

    private func healthScoreColor(_ score: Int) -> Color {
        if score >= 86 { return Color(hex: "10B981") }
        if score >= 71 { return Color(hex: "22C55E") }
        if score >= 51 { return ColorTheme.accent }
        if score >= 31 { return Color(hex: "F59E0B") }
        return Color(hex: "EF4444")
    }

    private func healthScoreLabel(_ score: Int) -> String {
        if score >= 86 { return "Elite" }
        if score >= 71 { return "Great" }
        if score >= 51 { return "Good" }
        if score >= 31 { return "Fair" }
        return "Poor"
    }
}
