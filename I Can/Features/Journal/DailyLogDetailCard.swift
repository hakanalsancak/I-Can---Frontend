import SwiftUI

// MARK: - Card for Journal list

struct DailyLogDetailCard: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme

    private var log: DailyLogResponses? { entry.dailyLogResponses }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Label("Daily Log", systemImage: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                if let date = entry.date {
                    Text(date, style: .date)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }

            // Completion
            if let log {
                HStack(spacing: 4) {
                    Text("\(log.completionCount)/3")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(log.isFullyComplete ? Color(hex: "22C55E") : ColorTheme.accent)
                    Text("completed")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Spacer()
                }

                // Section pills
                HStack(spacing: 8) {
                    sectionPill(
                        icon: "figure.run", label: "Training",
                        color: ColorTheme.training, done: log.hasTraining
                    )
                    sectionPill(
                        icon: "leaf.fill", label: "Nutrition",
                        color: ColorTheme.nutrition, done: log.hasNutrition
                    )
                    sectionPill(
                        icon: "moon.fill", label: "Sleep",
                        color: ColorTheme.sleep, done: log.hasSleep
                    )
                }

                // Highlights
                if let t = log.training {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ColorTheme.training)
                        Text(t.summaryText)
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }

                if let s = log.sleep {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ColorTheme.sleep)
                        Text(s.durationFormatted)
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private func sectionPill(icon: String, label: String, color: Color, done: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: done ? "checkmark.circle.fill" : icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(done ? color : ColorTheme.tertiaryText(colorScheme))
            Text(label)
                .font(.system(size: 11, weight: .semibold).width(.condensed))
                .foregroundColor(done ? color : ColorTheme.tertiaryText(colorScheme))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(done ? color.opacity(0.1) : ColorTheme.elevatedBackground(colorScheme))
        .clipShape(Capsule())
    }
}

// MARK: - Detail Sheet

struct DailyLogDetailSheet: View {
    let entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var log: DailyLogResponses? { entry.dailyLogResponses }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("DAILY LOG")
                                .font(.system(size: 11, weight: .heavy).width(.condensed))
                                .foregroundColor(ColorTheme.accent)

                            if let log {
                                Spacer()
                                Text("\(log.completionCount)/3")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundColor(log.isFullyComplete ? Color(hex: "22C55E") : ColorTheme.accent)
                            }
                        }

                        if let date = entry.date {
                            Text(date, style: .date)
                                .font(.system(size: 14, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)

                    if let log {
                        // Training Section
                        if let t = log.training {
                            trainingCard(t)
                        }

                        // Nutrition Section
                        if let n = log.nutrition {
                            nutritionCard(n)
                        }

                        // Sleep Section
                        if let s = log.sleep {
                            sleepCard(s)
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
                    Text("Log Details")
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

    // MARK: - Training Card

    private func trainingCard(_ t: TrainingData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(icon: "figure.run", title: "TRAINING", color: ColorTheme.training)
                Spacer()
                Text("\(t.sessionCount) session\(t.sessionCount == 1 ? "" : "s") - \(t.totalDuration)min")
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            ForEach(t.sessions) { session in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: session.trainingTypeIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ColorTheme.training)
                        Text(session.trainingTypeDisplay)
                            .font(.system(size: 14, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Spacer()

                        // Session score badge
                        if let score = session.sessionScore {
                            Text("\(score)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(score >= 80 ? Color(hex: "22C55E") : score >= 50 ? ColorTheme.accent : Color(hex: "F97316"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background((score >= 80 ? Color(hex: "22C55E") : score >= 50 ? ColorTheme.accent : Color(hex: "F97316")).opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    // Type-specific summary line
                    Text(session.typeSpecificSummary)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    // Match details: result, win method, rating
                    if session.trainingType == "match" {
                        FlowLayout(spacing: 6) {
                            if let result = session.resultDisplay {
                                let rc: Color = result == "Win" ? Color(hex: "22C55E") : result == "Loss" ? Color(hex: "EF4444") : Color(hex: "F59E0B")
                                journalBadge(text: result.uppercased(), color: rc)
                            }
                            if let wm = session.winMethodDisplay {
                                journalBadge(text: wm, color: ColorTheme.training)
                            }
                            if let rating = session.performanceRating {
                                journalBadge(text: "★ \(rating)/10", color: Color(hex: "F59E0B"))
                            }
                            if let mp = session.minutesPlayed {
                                journalBadge(text: "\(mp)min", color: ColorTheme.secondaryText(colorScheme))
                            }
                            if let p = session.position, !p.isEmpty {
                                journalBadge(text: p, color: ColorTheme.secondaryText(colorScheme))
                            }
                        }

                        if let stats = session.keyStats, !stats.isEmpty {
                            let ordered = stats.filter { $0.value > 0 }.sorted { $0.key < $1.key }
                            if !ordered.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(ordered, id: \.key) { key, value in
                                        journalBadge(text: "\(value) \(humanize(key))", color: ColorTheme.training)
                                    }
                                }
                            }
                        }
                    }

                    // Gym: focus + effort
                    if session.trainingType == "gym" {
                        FlowLayout(spacing: 6) {
                            if let f = session.gymFocusDisplay { journalBadge(text: f, color: ColorTheme.training) }
                            if let e = session.effortLevelDisplay { journalBadge(text: e, color: Color(hex: "F59E0B")) }
                        }
                    }

                    // Cardio
                    if session.trainingType == "cardio" {
                        FlowLayout(spacing: 6) {
                            if let ct = session.cardioTypeDisplay { journalBadge(text: ct, color: ColorTheme.training) }
                            if let d = session.distance {
                                let unit = session.distanceUnit ?? "km"
                                journalBadge(text: String(format: "%.1f %@", d, unit), color: ColorTheme.training)
                            }
                            if let s = session.steps, s > 0, session.cardioType == "walk" {
                                journalBadge(text: "\(s) steps", color: ColorTheme.training)
                            }
                            if let p = session.pace, !p.isEmpty { journalBadge(text: p, color: ColorTheme.secondaryText(colorScheme)) }
                            if let e = session.cardioEffortDisplay { journalBadge(text: e, color: Color(hex: "F59E0B")) }
                        }
                    }

                    // Technical
                    if session.trainingType == "technical" {
                        FlowLayout(spacing: 6) {
                            if let s = session.skillTrained, !s.isEmpty { journalBadge(text: s, color: ColorTheme.training) }
                            if let q = session.focusQualityDisplay { journalBadge(text: q, color: Color(hex: "F59E0B")) }
                        }
                    }

                    // Tactical
                    if session.trainingType == "tactical" {
                        FlowLayout(spacing: 6) {
                            if let t = session.tacticalTypeDisplay { journalBadge(text: t, color: ColorTheme.training) }
                            if let u = session.understandingLevelDisplay { journalBadge(text: u, color: Color(hex: "F59E0B")) }
                        }
                    }

                    // Recovery
                    if session.trainingType == "recovery" {
                        if let r = session.recoveryTypeDisplay {
                            FlowLayout(spacing: 6) {
                                journalBadge(text: r, color: ColorTheme.training)
                            }
                        }
                    }

                    if !session.details.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(session.details, id: \.self) { detail in
                                Text(detail)
                                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                                    .foregroundColor(ColorTheme.training)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.training.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }

                    if let exercises = session.exercises, !exercises.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(exercises, id: \.self) { ex in
                                Text(ex)
                                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "8B5CF6").opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }

                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 13, weight: .regular).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.training.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Nutrition Card

    private func nutritionCard(_ n: NutritionData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "leaf.fill", title: "NUTRITION", color: ColorTheme.nutrition)

            if let b = n.breakfast, !b.isEmpty { mealRow(icon: "sunrise.fill", label: "Breakfast", value: b) }
            if let l = n.lunch, !l.isEmpty { mealRow(icon: "sun.max.fill", label: "Lunch", value: l) }
            if let d = n.dinner, !d.isEmpty { mealRow(icon: "moon.fill", label: "Dinner", value: d) }
            if let s = n.snacks, !s.isEmpty { mealRow(icon: "carrot.fill", label: "Snacks", value: s) }
            if let d = n.drinks, !d.isEmpty { mealRow(icon: "drop.fill", label: "Drinks", value: d) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.nutrition.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Sleep Card

    private func sleepCard(_ s: SleepData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "moon.zzz.fill", title: "SLEEP", color: ColorTheme.sleep)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(s.durationFormatted)
                        .font(Typography.number(28))
                        .foregroundColor(ColorTheme.sleep)
                    Text("Duration")
                        .font(.system(size: 10, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text(s.sleepTime)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Bedtime")
                        .font(.system(size: 10, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text(s.wakeTime)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Wake up")
                        .font(.system(size: 10, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.sleep.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .heavy).width(.condensed))
                .foregroundColor(color)
        }
    }

    private func detailPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .heavy).width(.condensed))
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

    private func mealRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ColorTheme.nutrition)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 14, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .lineSpacing(2)
            }

            Spacer()
        }
    }

    private func journalBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold).width(.condensed))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func humanize(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
