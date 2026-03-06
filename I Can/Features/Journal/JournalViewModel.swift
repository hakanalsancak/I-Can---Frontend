import Foundation

@Observable
final class JournalViewModel {
    var entries: [DailyEntry] = []
    var selectedDate: Date = Date()
    var selectedEntry: DailyEntry?
    var isLoading = false
    var currentMonth: Date = Date()

    var entryDates: Set<String> {
        Set(entries.map { $0.entryDate })
    }

    var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    var firstWeekdayOffset: Int {
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    func loadEntries() async {
        isLoading = true
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)
        else { return }

        do {
            entries = try await EntryService.shared.getEntries(
                startDate: firstDay.apiDateString,
                endDate: lastDay.apiDateString,
                limit: 31
            )
        } catch {
            entries = []
        }
        isLoading = false
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        let dateStr = date.apiDateString
        selectedEntry = entries.first { $0.entryDate == dateStr }
    }

    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}
