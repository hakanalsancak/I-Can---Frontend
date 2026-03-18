import Foundation

@MainActor
@Observable
final class HomeViewModel {
    var streak: StreakInfo?
    var todayEntry: DailyEntry?
    var showDailyEntry = false
    var isLoading = false

    var hasLoggedToday: Bool { todayEntry != nil }

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
            todayEntry = try await EntryService.shared.getEntry(date: today)
        } catch let error as APIError {
            switch error {
            case .serverError(let msg) where msg.lowercased().contains("no entry") || msg.contains("404"):
                todayEntry = nil
            default:
                break
            }
        } catch {
            // Keep existing entry on transient failures
        }
    }

    func onEntrySubmitted(response: EntrySubmitResponse) {
        todayEntry = response.entry
        streak = response.streak
        showDailyEntry = false
        NotificationService.shared.cancelStreakReminder()
    }
}
