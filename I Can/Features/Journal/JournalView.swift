import SwiftUI

struct JournalView: View {
    @State private var viewModel = JournalViewModel()
    @State private var showSubscription = false
    @State private var showEntryDetail = false
    @FocusState private var isNoteFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Journal")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if SubscriptionService.shared.statusChecked && !SubscriptionService.shared.isPremium {
                            AIReportPromoCard(style: .journal) {
                                showSubscription = true
                            }
                        }

                        calendarSection
                        if let entry = viewModel.selectedEntry {
                            Button {
                                showEntryDetail = true
                                HapticManager.impact(.light)
                            } label: {
                                if entry.isDailyLog {
                                    DailyLogDetailCard(entry: entry)
                                } else {
                                    EntryDetailView(entry: entry)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            noEntryCard
                        }

                        // Note of the Day
                        noteSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .onTapGesture { isNoteFocused = false }
            .navigationBarHidden(true)
            .task { viewModel.loadEntries() }
            .onDisappear { viewModel.flushNote() }
            .onChange(of: viewModel.currentMonth) { _, _ in
                viewModel.loadEntries()
            }
            .sheet(isPresented: $showSubscription, onDismiss: {
                Task { try? await SubscriptionService.shared.checkStatus() }
            }) {
                SubscriptionView()
            }
            .sheet(isPresented: $showEntryDetail) {
                if let entry = viewModel.selectedEntry {
                    if entry.isDailyLog {
                        DailyLogDetailSheet(entry: entry)
                    } else {
                        TodayEntryDetailSheet(entry: entry)
                    }
                }
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

            let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
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

                ForEach(viewModel.daysInMonth, id: \.timeIntervalSinceReferenceDate) { date in
                    let dateStr = date.apiDateString
                    let entry = viewModel.entries.first { $0.entryDate == dateStr }
                    let hasEntry = entry != nil
                    let isSelected = date.apiDateString == viewModel.selectedDate.apiDateString
                    let isToday = Calendar.current.isDateInToday(date)

                    Button {
                        viewModel.selectDate(date)
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 15, weight: isToday || isSelected ? .semibold : .regular).width(.condensed))
                                .foregroundColor(
                                    isSelected ? .white :
                                    isToday ? ColorTheme.accent :
                                    ColorTheme.primaryText(colorScheme)
                                )

                            if hasEntry {
                                calendarDot(entry: entry, isSelected: isSelected)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 5, height: 5)
                            }
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

    @ViewBuilder
    private func calendarDot(entry: DailyEntry?, isSelected: Bool) -> some View {
        if let entry, entry.isDailyLog, let log = entry.dailyLogResponses {
            // Show completion dots for daily logs
            HStack(spacing: 2) {
                Circle()
                    .fill(log.hasTraining ? (isSelected ? .white.opacity(0.8) : ColorTheme.training) : Color.clear)
                    .frame(width: 4, height: 4)
                Circle()
                    .fill(log.hasNutrition ? (isSelected ? .white.opacity(0.8) : ColorTheme.nutrition) : Color.clear)
                    .frame(width: 4, height: 4)
                Circle()
                    .fill(log.hasSleep ? (isSelected ? .white.opacity(0.8) : ColorTheme.sleep) : Color.clear)
                    .frame(width: 4, height: 4)
            }
        } else {
            Circle()
                .fill(isSelected ? .white.opacity(0.8) : ColorTheme.accent)
                .frame(width: 5, height: 5)
        }
    }

    // MARK: - Note of the Day

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ColorTheme.accent)
                Text("Note of the Day")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Spacer()

                if viewModel.isSavingNote {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            Text("Your private space -- not shared with AI or reports.")
                .font(.system(size: 11, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))

            TextField("Write something about your day...", text: Binding(
                get: { viewModel.selectedNote },
                set: { viewModel.updateNote($0) }
            ), axis: .vertical)
                .font(.system(size: 14, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineLimit(3...10)
                .focused($isNoteFocused)
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if isNoteFocused {
                Button {
                    isNoteFocused = false
                    viewModel.flushNote()
                    HapticManager.impact(.light)
                } label: {
                    Text("SAVE")
                        .font(.system(size: 13, weight: .heavy).width(.condensed))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ColorTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.2), value: isNoteFocused)
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
