import Foundation

@MainActor
@Observable
final class HomeViewModel {
    var streak: StreakInfo?
    var todayEntry: DailyEntry?
    var showDailyEntry = false
    var isLoading = false

    // Daily Log state
    var todayTraining: TrainingData?
    var todayNutrition: NutritionData?
    var todaySleep: SleepData?
    var completedSections: [String] = []

    // Analytics
    var weeklyAnalytics: AnalyticsResponse?
    var monthlyAnalytics: AnalyticsResponse?
    var isLoadingAnalytics = false

    // Section sheets
    var showTrainingLog = false
    var showNutritionLog = false
    var showSleepLog = false

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

        if hasLoggedToday {
            NotificationService.shared.cancelStreakReminder()
        } else {
            NotificationService.shared.scheduleStreakReminder()
        }

        // Load analytics in background
        await loadAnalytics()
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
        async let weekTask = loadWeeklyAnalytics()
        async let monthTask = loadMonthlyAnalytics()
        _ = await (weekTask, monthTask)
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

    // MARK: - Section Submission

    func submitTraining(_ data: TrainingData) async {
        todayTraining = data
        if !completedSections.contains("training") {
            completedSections.append("training")
        }
        await saveDailyLog()
    }

    func submitNutrition(_ data: NutritionData) async {
        todayNutrition = data
        if !completedSections.contains("nutrition") {
            completedSections.append("nutrition")
        }
        await saveDailyLog()
    }

    func submitSleep(_ data: SleepData) async {
        todaySleep = data
        if !completedSections.contains("sleep") {
            completedSections.append("sleep")
        }
        await saveDailyLog()
    }

    private func saveDailyLog() async {
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
        } catch {
            // Revert on failure
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
}
