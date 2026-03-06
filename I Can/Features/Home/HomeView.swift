import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingSection
                    streakSection
                    dailyEntryCard
                    if let entry = viewModel.todayEntry {
                        todayScoreCard(entry)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("I Can")
            .refreshable { await viewModel.loadData() }
            .task { await viewModel.loadData() }
            .fullScreenCover(isPresented: $viewModel.showDailyEntry) {
                DailyEntryFlowView { response in
                    viewModel.onEntrySubmitted(response: response)
                }
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(Typography.title2)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            if let mantra = AuthService.shared.currentUser?.mantra, !mantra.isEmpty {
                Text("\"\(mantra)\"")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var streakSection: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    HStack(spacing: 6) {
                        Text("🔥")
                        Text("\(viewModel.streak?.currentStreak ?? 0) Day Streak")
                            .font(Typography.title3)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Text("\(viewModel.streak?.longestStreak ?? 0)")
                        .font(Typography.title3)
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private var dailyEntryCard: some View {
        Button {
            viewModel.showDailyEntry = true
        } label: {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: viewModel.hasLoggedToday ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(viewModel.hasLoggedToday ? .green : ColorTheme.accent)

                        Text(viewModel.hasLoggedToday ? "Today's Entry Logged" : "Log Today's Performance")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        Text(viewModel.hasLoggedToday ? "Tap to update your entry" : "Takes less than 2 minutes")
                            .font(Typography.footnote)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
        }
    }

    private func todayScoreCard(_ entry: DailyEntry) -> some View {
        CardView {
            VStack(spacing: 12) {
                Text("Today's Performance")
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                Text("\(entry.performanceScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(ColorTheme.accent)

                HStack(spacing: 24) {
                    ratingPill(label: "Focus", value: entry.focusRating)
                    ratingPill(label: "Effort", value: entry.effortRating)
                    ratingPill(label: "Confidence", value: entry.confidenceRating)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func ratingPill(label: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(Typography.title3)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text(label)
                .font(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}
