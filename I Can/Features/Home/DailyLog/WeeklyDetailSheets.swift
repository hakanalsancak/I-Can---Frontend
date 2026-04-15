import SwiftUI

// MARK: - Weekly Training Detail View

struct WeeklyTrainingDetailView: View {
    let data: AnalyticsResponse
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Summary card
                    if let summary = data.trainingSummary {
                        summaryCard(summary)
                    }

                    // Daily breakdown
                    ForEach(data.dailyData.indices, id: \.self) { index in
                        let day = data.dailyData[index]
                        if day.training, let duration = day.trainingDuration {
                            dayTrainingCard(day, dayIndex: index, duration: duration)
                        }
                    }

                    if data.trainingSessions == 0 {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Weekly Training")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private func summaryCard(_ summary: AnalyticsTrainingSummary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                statBubble(value: "\(summary.totalSessions)", label: "Sessions", color: ColorTheme.training)
                statBubble(value: formatDuration(summary.totalDuration), label: "Total Time", color: ColorTheme.training)
                statBubble(value: "\(summary.avgDuration)m", label: "Avg Session", color: ColorTheme.training)
            }

            // Type breakdown
            if !summary.typeBreakdown.isEmpty {
                HStack(spacing: 8) {
                    ForEach(summary.typeBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                        HStack(spacing: 4) {
                            Image(systemName: trainingTypeIcon(type))
                                .font(.system(size: 9, weight: .bold))
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold).width(.condensed))
                        }
                        .foregroundColor(ColorTheme.training)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.training.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func dayTrainingCard(_ day: AnalyticsDailyData, dayIndex: Int, duration: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayLabel(day.date))
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Text(formatDuration(duration))
                    .font(.system(size: 12, weight: .bold).width(.condensed))
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
                            Text("\(session.duration)min")
                                .font(.system(size: 11, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }

                        Spacer()

                        Text(session.intensity.capitalized)
                            .font(.system(size: 10, weight: .bold).width(.condensed))
                            .foregroundColor(intensityColor(session.intensity))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(intensityColor(session.intensity).opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if i < sessions.count - 1 {
                        Divider().foregroundColor(ColorTheme.separator(colorScheme))
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.run")
                .font(.system(size: 28))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Text("No training logged this week")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 20)
    }

    private func statBubble(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Typography.number(16))
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

    private func dayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
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
}

// MARK: - Weekly Nutrition Detail View

struct WeeklyNutritionDetailView: View {
    let data: AnalyticsResponse
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Summary card
                    if let summary = data.nutritionSummary {
                        nutritionSummaryCard(summary)
                    }

                    // Daily breakdown
                    ForEach(data.dailyData.indices, id: \.self) { index in
                        let day = data.dailyData[index]
                        if day.nutrition, let detail = day.nutritionDetail {
                            dayNutritionCard(day, detail: detail)
                        }
                    }

                    if data.nutritionDays == 0 {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Weekly Nutrition")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private func nutritionSummaryCard(_ summary: AnalyticsNutritionSummary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Avg health score ring
                healthScoreRing(score: summary.avgHealthScore, size: 64, lineWidth: 6)

                VStack(alignment: .leading, spacing: 6) {
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
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func dayNutritionCard(_ day: AnalyticsDailyData, detail: AnalyticsNutritionDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayLabel(day.date))
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                healthScoreRing(score: detail.healthScore, size: 32, lineWidth: 3)
            }

            VStack(alignment: .leading, spacing: 8) {
                if detail.breakfast {
                    mealRow(icon: "sunrise.fill", label: "Breakfast", text: detail.breakfastText, color: Color(hex: "F59E0B"))
                }
                if detail.lunch {
                    mealRow(icon: "sun.max.fill", label: "Lunch", text: detail.lunchText, color: ColorTheme.training)
                }
                if detail.dinner {
                    mealRow(icon: "moon.stars.fill", label: "Dinner", text: detail.dinnerText, color: ColorTheme.sleep)
                }
                if detail.snacks {
                    mealRow(icon: "takeoutbag.and.cup.and.straw.fill", label: "Snacks", text: detail.snacksText, color: Color(hex: "22C55E"))
                }
                if detail.drinks {
                    mealRow(icon: "cup.and.saucer.fill", label: "Drinks", text: detail.drinksText, color: ColorTheme.accent)
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func mealRow(icon: String, label: String, text: String?, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
                if let text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 28))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Text("No nutrition logged this week")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 20)
    }

    private func dayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

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
                .font(Typography.number(size > 50 ? 22 : 12))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
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

// MARK: - Weekly Sleep Detail View

struct WeeklySleepDetailView: View {
    let data: AnalyticsResponse
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Summary card
                    sleepSummaryCard

                    // Daily breakdown
                    ForEach(data.dailyData.indices, id: \.self) { index in
                        let day = data.dailyData[index]
                        if day.sleep, let hours = day.sleepHours {
                            daySleepCard(day, hours: hours)
                        }
                    }

                    if data.sleepDays == 0 {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Weekly Sleep")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private var sleepSummaryCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                if let avg = data.avgSleepHours {
                    Text(String(format: "%.1f", avg))
                        .font(Typography.number(32))
                        .foregroundColor(ColorTheme.sleep)
                    Text("avg hours")
                        .font(.system(size: 10, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .textCase(.uppercase)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text("\(data.sleepDays)")
                    .font(Typography.number(24))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("days logged")
                    .font(.system(size: 10, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }

            Spacer()

            VStack(spacing: 4) {
                if let avg = data.avgSleepHours {
                    Text(sleepQualityLabel(avg))
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(sleepQualityColor(avg))
                }
                Text("quality")
                    .font(.system(size: 10, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func daySleepCard(_ day: AnalyticsDailyData, hours: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayLabel(day.date))
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Text(sleepQualityLabel(hours))
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(sleepQualityColor(hours))
            }

            HStack(spacing: 20) {
                // Hours
                HStack(spacing: 6) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ColorTheme.sleep)
                    Text(String(format: "%.1fh", hours))
                        .font(Typography.number(18))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                Spacer()

                // Sleep / Wake times
                if let sleepTime = day.sleepTime, let wakeTime = day.wakeTime {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(ColorTheme.sleep)
                            Text(formatTime(sleepTime))
                                .font(.system(size: 12, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "sunrise.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text(formatTime(wakeTime))
                                .font(.system(size: 12, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                    }
                }
            }

            // Sleep bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorTheme.separator(colorScheme))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(sleepQualityColor(hours))
                        .frame(width: max(4, geo.size.width * CGFloat(min(hours, 12)) / 12), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.fill")
                .font(.system(size: 28))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Text("No sleep logged this week")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 20)
    }

    private func dayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let min = Int(parts[1]) else { return time }
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let ampm = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h12, min, ampm)
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
}

// MARK: - Day Training Detail View (tapping a single bar)

struct DayTrainingDetailView: View {
    let day: AnalyticsDailyData
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if let duration = day.trainingDuration {
                        // Duration header
                        VStack(spacing: 6) {
                            Text(formatDuration(duration))
                                .font(Typography.number(36))
                                .foregroundColor(ColorTheme.training)
                            Text("Total Training")
                                .font(.system(size: 11, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                    }

                    if let sessions = day.trainingSessions, !sessions.isEmpty {
                        ForEach(sessions.indices, id: \.self) { i in
                            sessionCard(sessions[i])
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 28))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            Text("No session details available")
                                .font(.system(size: 14, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(dayLabel(day.date))
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private func sessionCard(_ session: AnalyticsSessionData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ColorTheme.training.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: trainingTypeIcon(session.type))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ColorTheme.training)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.type.capitalized)
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("\(session.duration) minutes")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                if let score = session.sessionScore {
                    Text("\(score)")
                        .font(.system(size: 13, weight: .bold).width(.condensed))
                        .foregroundColor(scoreColor(score))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(scoreColor(score).opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text(session.intensity.capitalized)
                        .font(.system(size: 11, weight: .bold).width(.condensed))
                        .foregroundColor(intensityColor(session.intensity))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(intensityColor(session.intensity).opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            let badges = sessionBadges(session)
            if !badges.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(badges.indices, id: \.self) { i in
                        detailChip(text: badges[i].text, color: badges[i].color)
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func sessionBadges(_ s: AnalyticsSessionData) -> [(text: String, color: Color)] {
        var out: [(String, Color)] = []
        let accent = ColorTheme.training
        let warn = Color(hex: "F59E0B")
        let muted = ColorTheme.secondaryText(colorScheme)

        switch s.type {
        case "match":
            if let r = s.result, !r.isEmpty { out.append((r.uppercased(), resultColor(r))) }
            if let wm = s.winMethod, !wm.isEmpty { out.append((humanize(wm), accent)) }
            if let pr = s.performanceRating { out.append(("★ \(pr)/10", warn)) }
            if let mp = s.minutesPlayed { out.append(("\(mp)min", muted)) }
            if let p = s.position, !p.isEmpty { out.append((p, muted)) }
            if let ks = s.keyStats {
                for (k, v) in ks.sorted(by: { $0.key < $1.key }) where v > 0 {
                    out.append(("\(v) \(humanize(k))", accent))
                }
            }
        case "gym":
            if let f = s.gymFocus, !f.isEmpty { out.append((humanize(f), accent)) }
            if let e = s.effortLevel, !e.isEmpty { out.append((humanize(e), warn)) }
            if let ex = s.exercises { for e in ex where !e.isEmpty { out.append((e, muted)) } }
        case "cardio":
            if let ct = s.cardioType, !ct.isEmpty { out.append((humanize(ct), accent)) }
            if let d = s.distance { out.append((String(format: "%.1f km", d), accent)) }
            if let p = s.pace, !p.isEmpty { out.append((p, muted)) }
            if let e = s.cardioEffort, !e.isEmpty { out.append((humanize(e), warn)) }
        case "technical":
            if let sk = s.skillTrained, !sk.isEmpty { out.append((sk, accent)) }
            if let q = s.focusQuality, !q.isEmpty { out.append((humanize(q), warn)) }
        case "tactical":
            if let t = s.tacticalType, !t.isEmpty { out.append((humanize(t), accent)) }
            if let u = s.understandingLevel, !u.isEmpty { out.append((humanize(u), warn)) }
        case "recovery":
            if let r = s.recoveryType, !r.isEmpty { out.append((humanize(r), accent)) }
        default: break
        }
        return out
    }

    private func detailChip(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold).width(.condensed))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func resultColor(_ r: String) -> Color {
        switch r.lowercased() {
        case "win": return Color(hex: "22C55E")
        case "loss": return Color(hex: "EF4444")
        case "draw": return Color(hex: "F59E0B")
        default: return ColorTheme.secondaryText(colorScheme)
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color(hex: "22C55E") }
        if score >= 60 { return ColorTheme.training }
        if score >= 40 { return Color(hex: "F59E0B") }
        return Color(hex: "EF4444")
    }

    private func humanize(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private func dayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
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
}

// MARK: - Day Nutrition Detail View (tapping a single score circle)

struct DayNutritionDetailView: View {
    let day: AnalyticsDailyData
    let detail: AnalyticsNutritionDetail
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Score header
                    VStack(spacing: 10) {
                        healthScoreRing(score: detail.healthScore, size: 80, lineWidth: 8)

                        Text(healthScoreLabel(detail.healthScore))
                            .font(.system(size: 16, weight: .bold).width(.condensed))
                            .foregroundColor(healthScoreColor(detail.healthScore))

                        Text("\(detail.mealsLogged) meals logged")
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)

                    // Meals
                    VStack(alignment: .leading, spacing: 12) {
                        if detail.breakfast {
                            mealCard(icon: "sunrise.fill", label: "Breakfast", text: detail.breakfastText, color: Color(hex: "F59E0B"))
                        }
                        if detail.lunch {
                            mealCard(icon: "sun.max.fill", label: "Lunch", text: detail.lunchText, color: ColorTheme.training)
                        }
                        if detail.dinner {
                            mealCard(icon: "moon.stars.fill", label: "Dinner", text: detail.dinnerText, color: ColorTheme.sleep)
                        }
                        if detail.snacks {
                            mealCard(icon: "takeoutbag.and.cup.and.straw.fill", label: "Snacks", text: detail.snacksText, color: Color(hex: "22C55E"))
                        }
                        if detail.drinks {
                            mealCard(icon: "cup.and.saucer.fill", label: "Drinks", text: detail.drinksText, color: ColorTheme.accent)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(dayLabel(day.date))
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private func mealCard(icon: String, label: String, text: String?, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
                if let text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func dayLabel(_ dateStr: String) -> String {
        guard let date = Date.fromAPIString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

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
                .font(Typography.number(size > 50 ? 22 : 12))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
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
