import Foundation

@MainActor
@Observable
final class JournalViewModel {
    var entries: [DailyEntry] = []
    var selectedDate: Date = Date()
    var selectedEntry: DailyEntry?
    var isLoading = false
    var currentMonth: Date = Date()

    // Journal notes
    var notes: [String: String] = [:] // [dateStr: content]
    var selectedNote: String = ""
    var isSavingNote = false
    private var noteDebounceTask: Task<Void, Never>?

    private var loadTask: Task<Void, Never>?

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

    func loadEntries() {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            defer { isLoading = false }

            let calendar = Calendar.current
            guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
                  let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)
            else { return }

            do {
                async let entriesTask = EntryService.shared.getEntries(
                    startDate: firstDay.apiDateString,
                    endDate: lastDay.apiDateString,
                    limit: 31
                )
                async let notesTask = JournalNoteService.shared.getNotes(
                    start: firstDay.apiDateString,
                    end: lastDay.apiDateString
                )

                let (fetched, fetchedNotes) = try await (entriesTask, notesTask)
                guard !Task.isCancelled else { return }

                entries = fetched
                notes = Dictionary(
                    fetchedNotes.map { ($0.noteDate, $0.content) },
                    uniquingKeysWith: { _, last in last }
                )

                let dateStr = selectedDate.apiDateString
                selectedEntry = entries.first { $0.entryDate == dateStr }
                selectedNote = notes[dateStr] ?? ""
            } catch {
                guard !Task.isCancelled else { return }
                entries = []
                selectedEntry = nil
            }
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        let dateStr = date.apiDateString
        selectedEntry = entries.first { $0.entryDate == dateStr }
        selectedNote = notes[dateStr] ?? ""
    }

    func updateNote(_ text: String) {
        selectedNote = text
        let dateStr = selectedDate.apiDateString
        notes[dateStr] = text

        // Debounce save: wait 1.5s after user stops typing
        noteDebounceTask?.cancel()
        noteDebounceTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await saveNote(date: dateStr, content: text)
        }
    }

    /// Force-save the current note immediately (e.g. on disappear)
    func flushNote() {
        noteDebounceTask?.cancel()
        let dateStr = selectedDate.apiDateString
        let content = selectedNote
        Task {
            await saveNote(date: dateStr, content: content)
        }
    }

    private func saveNote(date: String, content: String) async {
        isSavingNote = true
        defer { isSavingNote = false }
        do {
            _ = try await JournalNoteService.shared.saveNote(date: date, content: content)
        } catch {
            // Silent fail — note is still in local state
        }
    }

    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}
