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

                // Completion Chart
                completionChart(data)

                // Sleep Chart
                if data.sleepDays > 0 {
                    sleepChart(data)
                }

                // Consistency bar
                consistencyBar(data)
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

    // MARK: - Completion Chart

    private func completionChart(_ data: AnalyticsResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DAILY COMPLETION")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(data.avgCompletion)% avg")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.accent)
            }

            let chartData = data.dailyData.map { item in
                DailyChartData(
                    date: item.date,
                    dayLabel: shortDayLabel(item.date),
                    completion: item.completion,
                    training: item.training,
                    nutrition: item.nutrition,
                    sleep: item.sleep,
                    sleepHours: item.sleepHours
                )
            }

            Chart(chartData) { item in
                BarMark(
                    x: .value("Day", item.dayLabel),
                    y: .value("Completion", item.completion)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: barColors(for: item.completion),
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
                        Text("\(value.as(Int.self) ?? 0)/3")
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
            .frame(height: 150)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: ColorTheme.training, label: "Training")
                legendItem(color: ColorTheme.nutrition, label: "Nutrition")
                legendItem(color: ColorTheme.sleep, label: "Sleep")
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
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

    // MARK: - Consistency Bar

    private func consistencyBar(_ data: AnalyticsResponse) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("CONSISTENCY")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                Text("\(data.consistencyPercent)%")
                    .font(Typography.number(18))
                    .foregroundColor(consistencyColor(data.consistencyPercent))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ColorTheme.elevatedBackground(colorScheme))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [ColorTheme.accent, consistencyColor(data.consistencyPercent)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(data.consistencyPercent) / 100), height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(data.totalDays) of \(data.expectedDays) days logged")
                    .font(.system(size: 11, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                Spacer()
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func shortDayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr.suffix(2).description }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func barColors(for completion: Int) -> [Color] {
        switch completion {
        case 3: return [ColorTheme.accent, Color(hex: "22C55E")]
        case 2: return [ColorTheme.accent, ColorTheme.accent.opacity(0.7)]
        case 1: return [Color(hex: "F97316"), Color(hex: "F97316").opacity(0.7)]
        default: return [ColorTheme.separator(colorScheme), ColorTheme.separator(colorScheme)]
        }
    }

    private func consistencyColor(_ percent: Int) -> Color {
        if percent >= 80 { return Color(hex: "22C55E") }
        if percent >= 50 { return ColorTheme.accent }
        return Color(hex: "F97316")
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
    }
}
