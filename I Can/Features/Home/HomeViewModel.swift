import Foundation

@MainActor
@Observable
final class HomeViewModel {
    static let shared = HomeViewModel()

    var streak: StreakInfo?
    var todayEntry: DailyEntry?
    var showDailyEntry = false
    var isLoading = false
    var saveError: String?

    // Daily Log state
    var todayTraining: TrainingData?
    var todayNutrition: NutritionData?
    var todaySleep: SleepData?
    var completedSections: [String] = []

    // Analytics
    var weeklyAnalytics: AnalyticsResponse?
    var monthlyAnalytics: AnalyticsResponse?
    var previousMonthAnalytics: AnalyticsResponse?
    var isLoadingAnalytics = false

    // Section sheets
    var showTrainingLog = false
    var showNutritionLog = false
    var showSleepLog = false

    // Training insight (shown inline in performance dashboard)
    var trainingInsight: String = ""
    var isLoadingTrainingInsight = false
    private var lastInsightTrainingData: TrainingData?

    // Nutrition insight (shown inline in performance dashboard)
    var nutritionInsight: String = ""
    var isLoadingNutritionInsight = false
    private var lastInsightNutritionData: NutritionData?

    private static let insightTextKey = "trainingInsight.text"
    private static let insightDateKey = "trainingInsight.date"
    private static let insightDataKey = "trainingInsight.data"
    private static let nutritionInsightTextKey = "nutritionInsight.text"
    private static let nutritionInsightDateKey = "nutritionInsight.date"
    private static let nutritionInsightDataKey = "nutritionInsight.data"

    private var isSaving = false
    private var hasLoadedInitially = false

    var hasLoggedToday: Bool { todayEntry != nil }

    var completionCount: Int { completedSections.count }

    var hasTraining: Bool { completedSections.contains("training") }
    var hasNutrition: Bool { completedSections.contains("nutrition") }
    var hasSleep: Bool { completedSections.contains("sleep") }

    func loadData() async {
        isLoading = true
        async let streakTask: () = loadStreak()
        async let entryTask: () = loadTodayEntry()
        _ = await (streakTask, entryTask)
        isLoading = false
        hasLoadedInitially = true

        let frequency = AuthService.shared.currentUser?.notificationFrequency ?? 1
        NotificationService.shared.scheduleAllNotifications(
            frequency: frequency,
            hasLoggedToday: hasLoggedToday
        )

        // Load analytics in background
        await loadAnalytics()
    }

    /// Called when the home tab becomes visible again.
    /// Skips if a save is in progress to avoid overwriting optimistic state,
    /// or if we haven't done the initial load yet (`.task` handles that).
    func refreshIfNeeded() async {
        guard hasLoadedInitially, !isSaving else { return }
        await loadTodayEntry()
    }

    private func loadStreak() async {
        do {
            streak = try await StreakService.shared.getStreak()
        } catch {
            // Streak will show 0
        }
    }

    private func loadTodayEntry() async {
        do {
            let today = Date().apiDateString
            let entry = try await EntryService.shared.getEntry(date: today)
            todayEntry = entry
            parseDailyLogData(from: entry)
        } catch let error as APIError {
            switch error {
            case .serverError(let msg) where msg.lowercased().contains("no entry") || msg.contains("404"):
                todayEntry = nil
                resetSections()
            default:
                break
            }
        } catch {
            // Keep existing entry on transient failures
        }
    }

    private func parseDailyLogData(from entry: DailyEntry) {
        if let log = entry.dailyLogResponses {
            todayTraining = log.training
            todayNutrition = log.nutrition
            todaySleep = log.sleep
            completedSections = log.completedSections
        } else {
            // Legacy entry - treat as training completed
            completedSections = ["training"]
            todayTraining = nil
            todayNutrition = nil
            todaySleep = nil
        }
    }

    private func resetSections() {
        todayTraining = nil
        todayNutrition = nil
        todaySleep = nil
        completedSections = []
    }

    func loadAnalytics() async {
        isLoadingAnalytics = true
        async let weekTask: Void = loadWeeklyAnalytics()
        async let monthTask: Void = loadMonthlyAnalytics()
        async let prevMonthTask: Void = loadPreviousMonthAnalytics()
        _ = await (weekTask, monthTask, prevMonthTask)
        isLoadingAnalytics = false
    }

    private func loadWeeklyAnalytics() async {
        do {
            weeklyAnalytics = try await DailyLogService.shared.getAnalytics(period: "week")
        } catch {}
    }

    private func loadMonthlyAnalytics() async {
        do {
            monthlyAnalytics = try await DailyLogService.shared.getAnalytics(period: "month")
        } catch {}
    }

    private func loadPreviousMonthAnalytics() async {
        do {
            previousMonthAnalytics = try await DailyLogService.shared.getAnalytics(period: "previous_month")
        } catch {}
    }

    // MARK: - Section Submission

    func submitTraining(_ data: TrainingData) async {
        let prevTraining = todayTraining
        let prevSections = completedSections

        todayTraining = data
        if !completedSections.contains("training") {
            completedSections.append("training")
        }

        if await saveDailyLog() {
            await fetchTrainingInsight(data)
        } else {
            todayTraining = prevTraining
            completedSections = prevSections
        }
    }

    private func fetchTrainingInsight(_ data: TrainingData) async {
        guard SubscriptionService.shared.isPremium else { return }
        // Only regenerate when training data actually changed
        if let last = lastInsightTrainingData, last == data, !trainingInsight.isEmpty {
            return
        }
        isLoadingTrainingInsight = true

        var request = InsightRequest(activityType: "Daily Log")
        request.trainingSessions = data.sessions.map { s in
            TrainingSessionInsight(
                trainingType: s.trainingType,
                duration: s.duration,
                matchType: s.matchType,
                result: s.result,
                performanceRating: s.performanceRating,
                minutesPlayed: s.minutesPlayed,
                position: s.position,
                keyStats: s.keyStats,
                gymFocus: s.gymFocus,
                effortLevel: s.effortLevel,
                exercises: s.exercises,
                cardioType: s.cardioType,
                distance: s.distance,
                pace: s.pace,
                cardioEffort: s.cardioEffort,
                skillTrained: s.skillTrained,
                focusQuality: s.focusQuality,
                tacticalType: s.tacticalType,
                understandingLevel: s.understandingLevel,
                recoveryType: s.recoveryType,
                sessionScore: s.sessionScore,
                notes: s.notes
            )
        }
        request.sessionScore = data.averageSessionScore

        do {
            let insight = try await EntryService.shared.generateInsight(request)
            if !insight.isEmpty {
                trainingInsight = insight
                lastInsightTrainingData = data
                persistInsight(insight, data: data)
            }
        } catch {
            // Silently fail - insight is a nice-to-have
        }
        isLoadingTrainingInsight = false
    }

    func submitNutrition(_ data: NutritionData) async {
        let prevNutrition = todayNutrition
        let prevSections = completedSections

        todayNutrition = data
        if !completedSections.contains("nutrition") {
            completedSections.append("nutrition")
        }

        if await saveDailyLog() {
            await fetchNutritionInsight(data)
        } else {
            todayNutrition = prevNutrition
            completedSections = prevSections
        }
    }

    private func fetchNutritionInsight(_ data: NutritionData) async {
        guard SubscriptionService.shared.isPremium else { return }
        if let last = lastInsightNutritionData, last == data, !nutritionInsight.isEmpty {
            return
        }
        isLoadingNutritionInsight = true

        // Pull the health score from today's analytics if available
        let today = Date().apiDateString
        let healthScore = weeklyAnalytics?.dailyData.first(where: { $0.date == today })?.nutritionDetail?.healthScore

        var request = InsightRequest(activityType: "Nutrition Log")
        request.nutrition = NutritionInsight(
            breakfast: data.breakfast,
            lunch: data.lunch,
            dinner: data.dinner,
            snacks: data.snacks,
            drinks: data.drinks,
            healthScore: healthScore,
            mealsLogged: data.mealsLogged
        )

        do {
            let insight = try await EntryService.shared.generateInsight(request)
            if !insight.isEmpty {
                nutritionInsight = insight
                lastInsightNutritionData = data
                persistNutritionInsight(insight, data: data)
            }
        } catch {
            // Silently fail - insight is a nice-to-have
        }
        isLoadingNutritionInsight = false
    }

    func submitSleep(_ data: SleepData) async {
        let prevSleep = todaySleep
        let prevSections = completedSections

        todaySleep = data
        if !completedSections.contains("sleep") {
            completedSections.append("sleep")
        }

        if !(await saveDailyLog()) {
            todaySleep = prevSleep
            completedSections = prevSections
        }
    }

    /// Returns true on success, false on failure.
    private func saveDailyLog() async -> Bool {
        isSaving = true
        defer { isSaving = false }
        saveError = nil
        do {
            let response = try await DailyLogService.shared.submitDailyLog(
                date: Date().apiDateString,
                training: todayTraining,
                nutrition: todayNutrition,
                sleep: todaySleep,
                completedSections: completedSections
            )
            todayEntry = response.entry
            streak = response.streak
            NotificationService.shared.cancelStreakReminder()

            // Refresh analytics after save
            await loadAnalytics()
            return true
        } catch {
            saveError = "Failed to save. Please try again."
            return false
        }
    }

    // Legacy support
    func onEntrySubmitted(response: EntrySubmitResponse) {
        todayEntry = response.entry
        streak = response.streak
        showDailyEntry = false
        parseDailyLogData(from: response.entry)
        NotificationService.shared.cancelStreakReminder()
    }

    private init() {
        loadPersistedInsight()
        loadPersistedNutritionInsight()
    }

    private func loadPersistedInsight() {
        let defaults = UserDefaults.standard
        guard let savedDate = defaults.string(forKey: Self.insightDateKey),
              savedDate == Date().apiDateString,
              let text = defaults.string(forKey: Self.insightTextKey),
              !text.isEmpty else {
            // Clean up stale insight from previous days
            defaults.removeObject(forKey: Self.insightTextKey)
            defaults.removeObject(forKey: Self.insightDateKey)
            defaults.removeObject(forKey: Self.insightDataKey)
            return
        }
        trainingInsight = text
        if let data = defaults.data(forKey: Self.insightDataKey),
           let decoded = try? JSONDecoder().decode(TrainingData.self, from: data) {
            lastInsightTrainingData = decoded
        }
    }

    private func persistInsight(_ text: String, data: TrainingData) {
        let defaults = UserDefaults.standard
        defaults.set(text, forKey: Self.insightTextKey)
        defaults.set(Date().apiDateString, forKey: Self.insightDateKey)
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: Self.insightDataKey)
        }
    }

    private func loadPersistedNutritionInsight() {
        let defaults = UserDefaults.standard
        guard let savedDate = defaults.string(forKey: Self.nutritionInsightDateKey),
              savedDate == Date().apiDateString,
              let text = defaults.string(forKey: Self.nutritionInsightTextKey),
              !text.isEmpty else {
            defaults.removeObject(forKey: Self.nutritionInsightTextKey)
            defaults.removeObject(forKey: Self.nutritionInsightDateKey)
            defaults.removeObject(forKey: Self.nutritionInsightDataKey)
            return
        }
        nutritionInsight = text
        if let data = defaults.data(forKey: Self.nutritionInsightDataKey),
           let decoded = try? JSONDecoder().decode(NutritionData.self, from: data) {
            lastInsightNutritionData = decoded
        }
    }

    private func persistNutritionInsight(_ text: String, data: NutritionData) {
        let defaults = UserDefaults.standard
        defaults.set(text, forKey: Self.nutritionInsightTextKey)
        defaults.set(Date().apiDateString, forKey: Self.nutritionInsightDateKey)
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: Self.nutritionInsightDataKey)
        }
    }
}
