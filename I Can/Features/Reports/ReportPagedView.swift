import SwiftUI

struct ReportPagedView: View {
    let report: AIReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var page = 0

    private var isWeekly: Bool { report.reportType == "weekly" }
    private var accent: Color { Color(hex: report.accentHex) }
    private var gradient: [Color] {
        isWeekly ? [Color(hex: "7C3AED"), Color(hex: "4F46E5")]
                 : [Color(hex: "2563EB"), Color(hex: "1D4ED8")]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: gradient.map { $0.opacity(colorScheme == .dark ? 0.35 : 0.18) } + [Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let content = report.content {
                    cardStack(content: content)
                } else {
                    LoadingView(message: "Loading report...")
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(isWeekly ? report.weekLabel : report.monthLabel)
                            .font(.system(size: 14, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text(report.dateRangeDisplay)
                            .font(.system(size: 11, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(accent)
                }
            }
        }
    }

    @ViewBuilder
    private func cardStack(content: ReportContent) -> some View {
        let pages: [AnyView] = isWeekly
            ? weeklyPages(content: content)
            : monthlyPages(content: content)

        TabView(selection: $page) {
            ForEach(pages.indices, id: \.self) { idx in
                pages[idx]
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 36)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func weeklyPages(content: ReportContent) -> [AnyView] {
        [
            AnyView(ScoreCard(report: report, content: content, gradient: gradient, accent: accent)),
            AnyView(PillarsCard(content: content, accent: accent)),
            AnyView(PeaksCard(content: content, accent: accent)),
            AnyView(WinsHitsCard(content: content)),
            AnyView(ActionCard(content: content, accent: accent, gradient: gradient, onShare: nil, onDone: { dismiss() }))
        ]
    }

    private func monthlyPages(content: ReportContent) -> [AnyView] {
        [
            AnyView(MonthScoreCard(report: report, content: content, gradient: gradient, accent: accent)),
            AnyView(ConsistencyGridCard(content: content, accent: accent)),
            AnyView(PillarTrendsCard(content: content, accent: accent)),
            AnyView(VerdictCard(content: content, accent: accent, gradient: gradient, onDone: { dismiss() }))
        ]
    }
}

// MARK: - Card Chrome

private struct CardShell<Content: View>: View {
    let title: String?
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 18) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            content
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Weekly Card 1: Score

private struct ScoreCard: View {
    let report: AIReport
    let content: ReportContent
    let gradient: [Color]
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    private var headline: String {
        if let h = content.headline, !h.isEmpty { return h }
        switch content.overallScore ?? 0 {
        case 90...: return "Elite week. Match it."
        case 80..<90: return "You were close to a perfect week."
        case 70..<80: return "Solid. Now sharpen the edges."
        case 60..<70: return "Below your bar. You know it."
        default: return "Rough week. Reset starts now."
        }
    }

    var body: some View {
        CardShell {
            VStack(spacing: 22) {
                Text(report.weekLabel.uppercased() + " · " + report.dateRangeDisplay)
                    .font(.system(size: 12, weight: .heavy).width(.condensed))
                    .tracking(1.2)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                ScoreRing(score: content.overallScore, gradient: gradient, size: 200)

                if let pct = content.improvementPct, let prev = content.prevOverallScore {
                    DeltaPill(score: content.overallScore ?? 0, previous: prev, pct: pct)
                }

                Text("\u{201C}\(headline)\u{201D}")
                    .font(.system(size: 19, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 6)

                if content.overallScore == nil, let summary = content.summary {
                    Text(summary)
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
        }
    }
}

// MARK: - Weekly Card 2: Pillars

private struct PillarsCard: View {
    let content: ReportContent
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    private var pillars: [(label: String, score: Int?, prev: Int?, color: Color, icon: String)] {
        [
            ("Training", content.trainingScore, content.prevTrainingScore, ColorTheme.training, "figure.run"),
            ("Nutrition", content.nutritionScore, content.prevNutritionScore, ColorTheme.nutrition, "leaf.fill"),
            ("Sleep", content.sleepScore, content.prevSleepScore, ColorTheme.sleep, "moon.zzz.fill")
        ]
    }

    private var lowestPillarLine: String? {
        let scored = pillars.compactMap { p -> (String, Int)? in
            guard let s = p.score else { return nil }
            return (p.label, s)
        }
        guard let lowest = scored.min(by: { $0.1 < $1.1 }) else { return nil }
        if scored.count >= 2 && scored.allSatisfy({ $0.1 >= 80 }) {
            return "All three pillars showing up."
        }
        switch lowest.0 {
        case "Training": return "Training is dragging you down."
        case "Nutrition": return "Nutrition is dragging you down."
        case "Sleep": return "Sleep is dragging you down."
        default: return nil
        }
    }

    var body: some View {
        CardShell(title: "How You Performed") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(pillars.indices, id: \.self) { i in
                        PillarTile(
                            label: pillars[i].label,
                            score: pillars[i].score,
                            previous: pillars[i].prev,
                            color: pillars[i].color,
                            icon: pillars[i].icon
                        )
                    }
                }

                if let line = lowestPillarLine {
                    Text(line)
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if let physical = content.physicalPatterns, content.trainingScore == nil {
                    Text(physical)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                }
            }
        }
    }
}

private struct PillarTile: View {
    let label: String
    let score: Int?
    let previous: Int?
    let color: Color
    let icon: String
    @Environment(\.colorScheme) private var colorScheme

    private var delta: Int? {
        guard let s = score, let p = previous else { return nil }
        return s - p
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)

            Text(label.uppercased())
                .font(.system(size: 11, weight: .heavy).width(.condensed))
                .tracking(0.8)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            Text(score.map { "\($0)" } ?? "—")
                .font(.system(size: 30, weight: .heavy, design: .rounded).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .monospacedDigit()

            if let d = delta {
                HStack(spacing: 2) {
                    Image(systemName: d >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .heavy))
                    Text("\(d >= 0 ? "+" : "")\(d)")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                }
                .foregroundColor(d >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444"))
            } else {
                Text(" ")
                    .font(.system(size: 11, weight: .heavy))
            }

            ProgressBar(value: Double(score ?? 0) / 100.0, color: color)
                .frame(height: 6)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Weekly Card 3: Peaks

private struct PeaksCard: View {
    let content: ReportContent
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CardShell(title: "The Week In Peaks") {
            VStack(spacing: 16) {
                if let best = content.bestDay {
                    DayHighlightRow(day: best, label: "Best Day", color: Color(hex: "22C55E"), icon: "trophy.fill")
                }
                if let worst = content.worstDay {
                    DayHighlightRow(day: worst, label: "Worst Day", color: Color(hex: "EF4444"), icon: "exclamationmark.triangle.fill")
                }

                if let scores = content.dailyScores, !scores.isEmpty {
                    DailySparkline(scores: scores, accent: accent)
                        .padding(.top, 4)
                }

                if content.bestDay == nil && content.worstDay == nil, let mental = content.mentalPatterns {
                    Text(mental)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .lineSpacing(3)
                }
            }
        }
    }
}

private struct DayHighlightRow: View {
    let day: DayHighlight
    let label: String
    let color: Color
    let icon: String
    @Environment(\.colorScheme) private var colorScheme

    private var displayDate: String {
        guard let d = Date.fromAPIString(day.date) else { return day.date }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE · MMM d"
        return fmt.string(from: d).uppercased()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label.uppercased())
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .tracking(0.8)
                        .foregroundColor(color)
                    Spacer()
                    Text("\(day.score)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .monospacedDigit()
                }
                Text(displayDate)
                    .font(.system(size: 12, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text(day.label)
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DailySparkline: View {
    let scores: [DailyScore]
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    private var maxScore: Double { max(Double(scores.map(\.score).max() ?? 100), 1) }

    private func dayInitial(_ dateStr: String) -> String {
        guard let d = Date.fromAPIString(dateStr) else { return "·" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEEE"
        return fmt.string(from: d)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(scores.indices, id: \.self) { i in
                    let s = scores[i]
                    let h = max(8, CGFloat(Double(s.score) / 100.0) * 80)
                    VStack(spacing: 4) {
                        Text("\(s.score)")
                            .font(.system(size: 9, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [accent.opacity(0.55), accent], startPoint: .bottom, endPoint: .top))
                            .frame(height: h)
                        Text(dayInitial(s.date))
                            .font(.system(size: 10, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Weekly Card 4: Wins / Hits

private struct WinsHitsCard: View {
    let content: ReportContent

    var body: some View {
        CardShell {
            VStack(spacing: 22) {
                BulletStack(
                    title: "What Went Well",
                    color: Color(hex: "22C55E"),
                    icon: "checkmark",
                    items: Array((content.strengths ?? []).prefix(3))
                )
                BulletStack(
                    title: "What Hurt You",
                    color: Color(hex: "EF4444"),
                    icon: "xmark",
                    items: Array((content.areasForImprovement ?? []).prefix(3))
                )
            }
        }
    }
}

private struct BulletStack: View {
    let title: String
    let color: Color
    let icon: String
    let items: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy).width(.condensed))
                .tracking(1.2)
                .foregroundColor(color)
            Rectangle()
                .fill(color.opacity(0.18))
                .frame(height: 1)
            VStack(alignment: .leading, spacing: 12) {
                if items.isEmpty {
                    Text("—")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                } else {
                    ForEach(items.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: icon)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(color)
                                .clipShape(Circle())
                            Text(items[i])
                                .font(.system(size: 14, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                .lineSpacing(2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weekly Card 5: Action

private struct ActionCard: View {
    let content: ReportContent
    let accent: Color
    let gradient: [Color]
    let onShare: (() -> Void)?
    let onDone: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var streak: Int { content.streakWeeks ?? 0 }
    private var streakLine: String {
        switch streak {
        case 12...: return "This is who you are now."
        case 4...11: return "Don\u{2019}t break the chain."
        case 1...3: return "Streak starting."
        default: return "Lock in week one."
        }
    }

    var body: some View {
        CardShell(title: "Do This Next Week") {
            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())

                    Text(content.primaryAction ?? content.motivationalMessage ?? "Show up. Log every day.")
                        .font(.system(size: 18, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("This is the move.")
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if streak > 0 {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "F97316"))
                        Text("\(streak)-week streak")
                            .font(.system(size: 16, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Spacer()
                        Text(streakLine)
                            .font(.system(size: 12, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(14)
                    .background(Color(hex: "F97316").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .heavy).width(.condensed))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

// MARK: - Monthly Card 1: Month Score

private struct MonthScoreCard: View {
    let report: AIReport
    let content: ReportContent
    let gradient: [Color]
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    private var headline: String {
        if let h = content.headline, !h.isEmpty { return h }
        let pct = content.improvementPct ?? 0
        if pct > 5 { return "Trending up. Stay on it." }
        if pct < -5 { return "Slipped this month. Reset." }
        return "Holding steady. Push the ceiling."
    }

    var body: some View {
        CardShell {
            VStack(spacing: 18) {
                Text(report.monthLabel.uppercased())
                    .font(.system(size: 12, weight: .heavy).width(.condensed))
                    .tracking(1.2)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                VStack(spacing: 4) {
                    Text("AVG SCORE")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .tracking(1)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(content.overallScore.map { "\($0)" } ?? "—")
                            .font(.system(size: 64, weight: .heavy, design: .rounded).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .monospacedDigit()
                        if let pct = content.improvementPct, content.prevOverallScore != nil {
                            DeltaPill(score: content.overallScore ?? 0, previous: content.prevOverallScore ?? 0, pct: pct)
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 6 }
                        }
                    }
                }

                if let weekly = content.weeklyScores, !weekly.isEmpty {
                    WeeklyTrendChart(weeks: weekly, accent: accent)
                        .frame(height: 130)
                        .padding(.top, 4)
                }

                Text("\u{201C}\(headline)\u{201D}")
                    .font(.system(size: 17, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }
}

private struct WeeklyTrendChart: View {
    let weeks: [WeeklyScore]
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let maxScore: CGFloat = 100
            let width = geo.size.width
            let height = geo.size.height - 28
            let stepX = weeks.count > 1 ? width / CGFloat(weeks.count - 1) : 0
            let points = weeks.enumerated().map { idx, w -> CGPoint in
                let x = CGFloat(idx) * stepX
                let y = height - (CGFloat(w.score) / maxScore) * height + 8
                return CGPoint(x: x, y: y)
            }

            ZStack {
                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(points.indices, id: \.self) { i in
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(ColorTheme.cardBackground(colorScheme), lineWidth: 2))
                        .position(points[i])
                    Text("\(weeks[i].score)")
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .position(x: points[i].x, y: max(points[i].y - 14, 6))
                }

                ForEach(weeks.indices, id: \.self) { i in
                    Text(weeks[i].label ?? "W\(weeks[i].weekIndex)")
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .position(x: CGFloat(i) * stepX, y: height + 20)
                }
            }
        }
    }
}

// MARK: - Monthly Card 2: Consistency Grid

private struct ConsistencyGridCard: View {
    let content: ReportContent
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    private var loggedCount: Int {
        (content.dailyScores ?? []).filter { $0.score > 0 }.count
    }

    private var totalDays: Int {
        max(content.dailyScores?.count ?? 0, 28)
    }

    private var bestStreak: Int {
        let scores = content.dailyScores ?? []
        var best = 0
        var current = 0
        for s in scores {
            if s.score > 0 { current += 1; best = max(best, current) }
            else { current = 0 }
        }
        return best
    }

    private var consistencyLine: String {
        guard totalDays > 0 else { return "Log days to build the grid." }
        let pct = Int((Double(loggedCount) / Double(totalDays)) * 100)
        switch pct {
        case 90...: return "\(pct)% consistency. Pro level."
        case 75..<90: return "\(pct)% consistency. Pros do 90%."
        case 50..<75: return "\(pct)% consistency. Half-in won\u{2019}t cut it."
        default: return "\(pct)% consistency. Show up daily."
        }
    }

    var body: some View {
        CardShell(title: "Consistency") {
            VStack(spacing: 18) {
                if let scores = content.dailyScores, !scores.isEmpty {
                    HeatmapGrid(scores: scores, color: accent)
                } else if let consistency = content.consistencyAnalysis {
                    Text(consistency)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 0) {
                    statCol(value: "\(loggedCount)/\(totalDays)", label: "Days Logged")
                    Divider().frame(height: 36).overlay(ColorTheme.separator(colorScheme))
                    statCol(value: "\(bestStreak)d", label: "Best Streak")
                }

                Text(consistencyLine)
                    .font(.system(size: 15, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func statCol(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .tracking(1)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HeatmapGrid: View {
    let scores: [DailyScore]
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    private let columns = 7
    private let spacing: CGFloat = 4

    private var rows: Int {
        max(1, (scores.count + columns - 1) / columns)
    }

    var body: some View {
        GeometryReader { geo in
            let cell = max(0, (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { c in
                            let idx = r * columns + c
                            if idx < scores.count {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(cellColor(scores[idx].score))
                                    .frame(width: cell, height: cell)
                            } else {
                                Color.clear.frame(width: cell, height: cell)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
    }

    private func cellColor(_ score: Int) -> Color {
        if score <= 0 {
            return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
        }
        let opacity = max(0.18, min(1.0, Double(score) / 100.0))
        return color.opacity(opacity)
    }
}

// MARK: - Monthly Card 3: Pillar Trends

private struct PillarTrendsCard: View {
    let content: ReportContent
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CardShell(title: "What\u{2019}s Changing") {
            VStack(spacing: 18) {
                trendRow(label: "Training", color: ColorTheme.training,
                         pct: content.pillarTrend?.trainingPct, note: content.pillarTrend?.trainingNote)
                trendRow(label: "Nutrition", color: ColorTheme.nutrition,
                         pct: content.pillarTrend?.nutritionPct, note: content.pillarTrend?.nutritionNote)
                trendRow(label: "Sleep", color: ColorTheme.sleep,
                         pct: content.pillarTrend?.sleepPct, note: content.pillarTrend?.sleepNote)
            }
        }
    }

    private func trendRow(label: String, color: Color, pct: Double?, note: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(label.uppercased())
                    .font(.system(size: 12, weight: .heavy).width(.condensed))
                    .tracking(1)
                    .foregroundColor(color)
                Spacer()
                if let pct {
                    HStack(spacing: 4) {
                        Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .heavy))
                        Text("\(pct >= 0 ? "+" : "")\(Int(pct.rounded()))%")
                            .font(.system(size: 14, weight: .heavy, design: .rounded).width(.condensed))
                    }
                    .foregroundColor(pct >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                } else {
                    Text("—").foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
            ProgressBar(value: min(1.0, max(0.0, abs(pct ?? 0) / 30.0)), color: color)
                .frame(height: 6)
            if let note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 13, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Monthly Card 4: Verdict

private struct VerdictCard: View {
    let content: ReportContent
    let accent: Color
    let gradient: [Color]
    let onDone: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CardShell(title: "Verdict") {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(content.letterGrade)
                        .font(.system(size: 60, weight: .heavy, design: .rounded).width(.condensed))
                        .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    if let score = content.overallScore {
                        Text("\(score) / 100")
                            .font(.system(size: 13, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }

                BulletStack(
                    title: "This Month",
                    color: Color(hex: "22C55E"),
                    icon: "checkmark",
                    items: Array((content.strengths ?? []).prefix(3))
                )

                if let areas = content.areasForImprovement, !areas.isEmpty {
                    BulletStack(
                        title: "What Cost You",
                        color: Color(hex: "EF4444"),
                        icon: "xmark",
                        items: Array(areas.prefix(3))
                    )
                }

                VStack(spacing: 10) {
                    Text("ONE FOCUS FOR NEXT MONTH")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .tracking(1.2)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text(content.primaryAction ?? "Log every day. No exceptions.")
                        .font(.system(size: 17, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .heavy).width(.condensed))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

// MARK: - Shared atoms

private struct ScoreRing: View {
    let score: Int?
    let gradient: [Color]
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedFraction: CGFloat = 0

    var body: some View {
        let fraction = CGFloat(min(max(score ?? 0, 0), 100)) / 100.0
        ZStack {
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.9, dampingFraction: 0.85), value: animatedFraction)

            VStack(spacing: 2) {
                Text(score.map { "\($0)" } ?? "—")
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .monospacedDigit()
                Text("/ 100")
                    .font(.system(size: 13, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .frame(width: size, height: size)
        .onAppear { animatedFraction = fraction }
    }
}

private struct DeltaPill: View {
    let score: Int
    let previous: Int
    let pct: Double
    @Environment(\.colorScheme) private var colorScheme

    private var diff: Int { score - previous }
    private var color: Color { diff >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444") }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 11, weight: .heavy))
            Text("\(diff >= 0 ? "+" : "")\(diff) vs last")
                .font(.system(size: 13, weight: .heavy).width(.condensed))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct ProgressBar: View {
    let value: Double
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(min(max(value, 0), 1))))
            }
        }
    }
}
