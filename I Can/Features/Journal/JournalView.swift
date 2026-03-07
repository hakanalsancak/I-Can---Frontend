import SwiftUI

struct JournalView: View {
    @State private var viewModel = JournalViewModel()
    @State private var showSubscription = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Journal")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if !SubscriptionService.shared.isPremium {
                            AIReportPromoCard(style: .journal) {
                                showSubscription = true
                            }
                        }

                        calendarSection
                        if let entry = viewModel.selectedEntry {
                            EntryDetailView(entry: entry)
                        } else {
                            noEntryCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.loadEntries() }
            .onChange(of: viewModel.currentMonth) { _, _ in
                Task { await viewModel.loadEntries() }
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }

    private var calendarSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(ColorTheme.subtleAccent(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()

                Text(viewModel.monthYearString)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Spacer()

                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(ColorTheme.subtleAccent(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdays[i])
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        .frame(height: 24)
                        .id("header-\(i)")
                }

                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { i in
                    Text("")
                        .id("spacer-\(i)")
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
                        VStack(spacing: 3) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 15, weight: isToday || isSelected ? .semibold : .regular).width(.condensed))
                                .foregroundColor(
                                    isSelected ? .white :
                                    isToday ? ColorTheme.accent :
                                    ColorTheme.primaryText(colorScheme)
                                )

                            Circle()
                                .fill(hasEntry ? (isSelected ? .white.opacity(0.8) : ColorTheme.accent) : .clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(width: 36, height: 42)
                        .background(
                            isSelected
                            ? AnyShapeStyle(ColorTheme.accentGradient)
                            : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var noEntryCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 28).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Text("No entry for this date")
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
