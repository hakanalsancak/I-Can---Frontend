import SwiftUI

struct JournalView: View {
    @State private var viewModel = JournalViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    calendarSection
                    if let entry = viewModel.selectedEntry {
                        EntryDetailView(entry: entry)
                    } else {
                        noEntryCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Journal")
            .task { await viewModel.loadEntries() }
            .onChange(of: viewModel.currentMonth) { _, _ in
                Task { await viewModel.loadEntries() }
            }
        }
    }

    private var calendarSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(ColorTheme.accent)
                }

                Spacer()

                Text(viewModel.monthYearString)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Spacer()

                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorTheme.accent)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                    Text("")
                }

                ForEach(viewModel.daysInMonth, id: \.self) { date in
                    let dateStr = date.apiDateString
                    let hasEntry = viewModel.entryDates.contains(dateStr)
                    let isSelected = date.apiDateString == viewModel.selectedDate.apiDateString
                    let isToday = Calendar.current.isDateInToday(date)

                    Button {
                        viewModel.selectDate(date)
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(Typography.callout)
                                .foregroundColor(
                                    isSelected ? .white :
                                    isToday ? ColorTheme.accent :
                                    ColorTheme.primaryText(colorScheme)
                                )

                            Circle()
                                .fill(hasEntry ? ColorTheme.accent : .clear)
                                .frame(width: 6, height: 6)
                        }
                        .frame(width: 36, height: 40)
                        .background(isSelected ? ColorTheme.accent : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noEntryCard: some View {
        CardView {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text("No entry for this date")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}
