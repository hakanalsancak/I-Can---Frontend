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
    let isLoading: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPeriod = 0 // 0 = week, 1 = month

    private var currentData: AnalyticsResponse? {
        selectedPeriod == 0 ? weeklyData : monthlyData
    }

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
                    periodTab("Week", index: 0)
                    periodTab("Month", index: 1)
                }
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if let data = currentData {
                // Stats Overview
                statsOverview(data)

                // Training Analytics
                if data.trainingSessions > 0, let summary = data.trainingSummary {
                    trainingAnalyticsSection(data, summary: summary)
                }

                // Nutrition Analytics
                if data.nutritionDays > 0, let summary = data.nutritionSummary {
                    nutritionAnalyticsSection(data, summary: summary)
                }

                // Sleep Chart
                if data.sleepDays > 0 {
                    sleepChart(data)
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 28))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    Text("Start logging to see your data")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(.vertical, 20)
            }
        }
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
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(selectedPeriod == index ? .white : ColorTheme.secondaryText(colorScheme))
                .padding(.horizontal, 16)
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

    // MARK: - Stats Overview

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

    // MARK: - Sleep Chart

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

            let sleepData = data.dailyData.compactMap { item -> (String, Double)? in
                guard let hours = item.sleepHours else { return nil }
                return (shortDayLabel(item.date), hours)
            }

            Chart(sleepData, id: \.0) { day, hours in
                LineMark(
                    x: .value("Day", day),
                    y: .value("Hours", hours)
                )
                .foregroundStyle(ColorTheme.sleep)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", day),
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
                    x: .value("Day", day),
                    y: .value("Hours", hours)
                )
                .foregroundStyle(ColorTheme.sleep)
                .symbolSize(24)
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

    // MARK: - Training Analytics

    private func trainingAnalyticsSection(_ data: AnalyticsResponse, summary: AnalyticsTrainingSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("TRAINING")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(summary.totalSessions) sessions")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.training)
            }

            // Duration & avg stats row
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

            // Daily training duration bar chart
            let trainingDays = data.dailyData.compactMap { item -> (String, Int)? in
                guard let dur = item.trainingDuration, dur > 0 else { return nil }
                return (shortDayLabel(item.date), dur)
            }

            if !trainingDays.isEmpty {
                Chart(trainingDays, id: \.0) { day, duration in
                    BarMark(
                        x: .value("Day", day),
                        y: .value("Minutes", duration)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.training, ColorTheme.training.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
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

            // Type breakdown
            if !summary.typeBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SESSION TYPES")
                        .font(.system(size: 9, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                    let sorted = summary.typeBreakdown.sorted { $0.value > $1.value }
                    let maxCount = sorted.first?.value ?? 1

                    ForEach(sorted, id: \.key) { type, count in
                        HStack(spacing: 8) {
                            Image(systemName: trainingTypeIcon(type))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(ColorTheme.training)
                                .frame(width: 16)

                            Text(type.capitalized)
                                .font(.system(size: 12, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                .frame(width: 70, alignment: .leading)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [ColorTheme.training, ColorTheme.training.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(4, geo.size.width * CGFloat(count) / CGFloat(maxCount)))
                            }
                            .frame(height: 8)

                            Text("\(count)")
                                .font(Typography.number(12))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        .frame(height: 20)
                    }
                }
            }

            // Intensity breakdown
            if !summary.intensityBreakdown.isEmpty {
                HStack(spacing: 8) {
                    let order = ["low", "medium", "high", "max"]
                    let total = summary.intensityBreakdown.values.reduce(0, +)
                    ForEach(order, id: \.self) { level in
                        if let count = summary.intensityBreakdown[level], count > 0 {
                            let pct = total > 0 ? Int(round(Double(count) / Double(total) * 100)) : 0
                            VStack(spacing: 3) {
                                Text("\(pct)%")
                                    .font(Typography.number(13))
                                    .foregroundColor(intensityColor(level))
                                Text(level.capitalized)
                                    .font(.system(size: 9, weight: .bold).width(.condensed))
                                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                                    .textCase(.uppercase)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Nutrition Analytics

    private func nutritionAnalyticsSection(_ data: AnalyticsResponse, summary: AnalyticsNutritionSummary) -> some View {
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

            // Top-level stats
            HStack(spacing: 10) {
                miniStat(
                    value: String(format: "%.1f", summary.avgMealsPerDay),
                    label: "Avg Meals/Day",
                    color: ColorTheme.nutrition
                )
                miniStat(
                    value: "\(summary.daysLogged)",
                    label: "Days Tracked",
                    color: ColorTheme.nutrition
                )
            }

            // Daily meals logged chart
            let nutritionDays = data.dailyData.compactMap { item -> (String, Int)? in
                guard let detail = item.nutritionDetail else { return nil }
                return (shortDayLabel(item.date), detail.mealsLogged)
            }

            if !nutritionDays.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MEALS PER DAY")
                        .font(.system(size: 9, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                    Chart(nutritionDays, id: \.0) { day, meals in
                        BarMark(
                            x: .value("Day", day),
                            y: .value("Meals", meals)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: mealCountColors(meals),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                    .chartYScale(domain: 0...3)
                    .chartYAxis {
                        AxisMarks(values: [0, 1, 2, 3]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(ColorTheme.separator(colorScheme))
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
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
                    .frame(height: 110)
                }
            }

            // Daily meal health rating
            let ratingDays = data.dailyData.compactMap { item -> (String, Int)? in
                guard let detail = item.nutritionDetail else { return nil }
                return (shortDayLabel(item.date), detail.mealRating)
            }

            if !ratingDays.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DAILY MEAL RATING")
                            .font(.system(size: 9, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        Spacer()
                        Text(String(format: "%.1f avg", summary.avgMealRating))
                            .font(.system(size: 11, weight: .bold).width(.condensed))
                            .foregroundColor(mealRatingColor(summary.avgMealRating))
                    }

                    Chart(ratingDays, id: \.0) { day, rating in
                        BarMark(
                            x: .value("Day", day),
                            y: .value("Rating", rating)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: mealRatingBarColors(rating),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                    .chartYScale(domain: 0...10)
                    .chartYAxis {
                        AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(ColorTheme.separator(colorScheme))
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
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

                    // Rating scale legend
                    HStack(spacing: 0) {
                        ratingLegendItem(label: "Poor", range: "1-3", color: Color(hex: "EF4444"))
                        ratingLegendItem(label: "Fair", range: "4-5", color: Color(hex: "F59E0B"))
                        ratingLegendItem(label: "Good", range: "6-7", color: ColorTheme.accent)
                        ratingLegendItem(label: "Great", range: "8-10", color: Color(hex: "22C55E"))
                    }
                }
            }

            // Daily meal breakdown (which meals each day)
            let detailDays = data.dailyData.compactMap { item -> (String, AnalyticsNutritionDetail)? in
                guard let detail = item.nutritionDetail else { return nil }
                return (shortDayLabel(item.date), detail)
            }

            if !detailDays.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAILY BREAKDOWN")
                        .font(.system(size: 9, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                    // Grid header
                    HStack(spacing: 0) {
                        Text("Day")
                            .frame(width: 36, alignment: .leading)
                        Spacer()
                        mealColumnHeader("B", color: Color(hex: "F59E0B"))
                        mealColumnHeader("L", color: ColorTheme.nutrition)
                        mealColumnHeader("D", color: Color(hex: "6366F1"))
                        mealColumnHeader("S", color: ColorTheme.secondaryText(colorScheme))
                        mealColumnHeader("W", color: ColorTheme.sleep)
                    }
                    .font(.system(size: 9, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                    ForEach(detailDays, id: \.0) { day, detail in
                        HStack(spacing: 0) {
                            Text(day)
                                .font(.system(size: 11, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                .frame(width: 36, alignment: .leading)
                            Spacer()
                            mealDot(filled: detail.breakfast, color: Color(hex: "F59E0B"))
                            mealDot(filled: detail.lunch, color: ColorTheme.nutrition)
                            mealDot(filled: detail.dinner, color: Color(hex: "6366F1"))
                            mealDot(filled: detail.snacks, color: ColorTheme.secondaryText(colorScheme))
                            mealDot(filled: detail.drinks, color: ColorTheme.sleep)
                        }
                    }
                }
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Nutrition Sub-Components

    private func ratingLegendItem(label: String, range: String, color: Color) -> some View {
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

    private func mealColumnHeader(_ label: String, color: Color) -> some View {
        Text(label)
            .foregroundColor(color)
            .frame(width: 36)
    }

    private func mealDot(filled: Bool, color: Color) -> some View {
        Circle()
            .fill(filled ? color : ColorTheme.separator(colorScheme))
            .frame(width: 8, height: 8)
            .frame(width: 36)
    }

    // MARK: - Shared Mini Stat

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

    // MARK: - Helpers

    private func shortDayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr.suffix(2).description }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
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

    private func mealCountColors(_ count: Int) -> [Color] {
        switch count {
        case 3: return [ColorTheme.nutrition, Color(hex: "22C55E")]
        case 2: return [ColorTheme.nutrition, ColorTheme.nutrition.opacity(0.7)]
        case 1: return [Color(hex: "F59E0B"), Color(hex: "F59E0B").opacity(0.7)]
        default: return [ColorTheme.separator(colorScheme), ColorTheme.separator(colorScheme)]
        }
    }

    private func mealRatingColor(_ rating: Double) -> Color {
        if rating >= 8 { return Color(hex: "22C55E") }
        if rating >= 6 { return ColorTheme.accent }
        if rating >= 4 { return Color(hex: "F59E0B") }
        return Color(hex: "EF4444")
    }

    private func mealRatingBarColors(_ rating: Int) -> [Color] {
        switch rating {
        case 8...10: return [Color(hex: "22C55E"), Color(hex: "22C55E").opacity(0.7)]
        case 6...7: return [ColorTheme.accent, ColorTheme.accent.opacity(0.7)]
        case 4...5: return [Color(hex: "F59E0B"), Color(hex: "F59E0B").opacity(0.7)]
        default: return [Color(hex: "EF4444"), Color(hex: "EF4444").opacity(0.7)]
        }
    }
}
