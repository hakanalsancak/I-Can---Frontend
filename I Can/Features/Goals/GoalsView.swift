import SwiftUI

struct GoalsView: View {
    @State private var viewModel = GoalsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Goals") {
                    Button {
                        HapticManager.impact(.light)
                        viewModel.showCreateGoal = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .heavy))
                            Text("ADD")
                                .font(.system(size: 11, weight: .heavy).width(.condensed))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ColorTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        filterSegments

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(ColorTheme.accent)
                                .padding(.top, 40)
                        } else if viewModel.filteredGoals.isEmpty {
                            emptyState
                        } else {
                            goalsList
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showCreateGoal) {
                GoalFormView { type, title, description in
                    Task {
                        await viewModel.createGoal(
                            type: type, title: title,
                            description: description
                        )
                    }
                }
            }
            .task { await viewModel.loadGoals() }
            .refreshable { await viewModel.loadGoals() }
            .overlay(alignment: .bottom) {
                addGoalButton
            }
        }
    }

    // MARK: - Filter Segments

    private var filterSegments: some View {
        HStack(spacing: 0) {
            ForEach(filterOptions, id: \.0) { filter in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectedFilter = filter.0
                    }
                } label: {
                    let isSelected = viewModel.selectedFilter == filter.0
                    VStack(spacing: 4) {
                        Text(filter.1)
                            .font(.system(size: 12, weight: isSelected ? .heavy : .semibold).width(.condensed))
                            .foregroundColor(
                                isSelected
                                ? ColorTheme.accent
                                : ColorTheme.secondaryText(colorScheme)
                            )
                        Text("\(filter.2)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(
                                isSelected
                                ? ColorTheme.accent
                                : ColorTheme.tertiaryText(colorScheme)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isSelected
                        ? ColorTheme.accent.opacity(colorScheme == .dark ? 0.12 : 0.08)
                        : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
        )
    }

    private var filterOptions: [(String?, String, Int)] {
        [
            (nil, "All", viewModel.goals.count),
            ("weekly", "Weekly", viewModel.weeklyCount),
            ("monthly", "Monthly", viewModel.monthlyCount),
            ("yearly", "Yearly", viewModel.yearlyCount),
        ]
    }

    // MARK: - Goals List

    private var goalsList: some View {
        VStack(spacing: 20) {
            let active = viewModel.filteredGoals.filter { !$0.isCompleted }
            let completed = viewModel.filteredGoals.filter { $0.isCompleted }

            if !active.isEmpty {
                goalsSection(title: "ACTIVE", count: active.count, goals: active)
            }

            if !completed.isEmpty {
                goalsSection(title: "COMPLETED", count: completed.count, goals: completed)
            }
        }
    }

    private func goalsSection(title: String, count: Int, goals: [Goal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                Text("\(count)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorTheme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .padding(.leading, 4)

            ForEach(goals) { goal in
                GoalCard(
                    goal: goal,
                    isJustCompleted: viewModel.justCompleted == goal.id,
                    colorScheme: colorScheme,
                    onToggle: {
                        Task { await viewModel.toggleComplete(goal) }
                    },
                    onDelete: {
                        Task { await viewModel.deleteGoal(goal) }
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "target")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(ColorTheme.accent)
            }

            VStack(spacing: 6) {
                Text("No Goals Yet")
                    .font(.system(size: 20, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Set weekly, monthly, or yearly goals\nto track your progress")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button {
                HapticManager.impact(.light)
                viewModel.showCreateGoal = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .heavy))
                    Text("Create Your First Goal")
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ColorTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 4)
        }
        .padding(.top, 40)
    }

    // MARK: - Floating Add Button

    private var addGoalButton: some View {
        Group {
            if !viewModel.goals.isEmpty {
                Button {
                    HapticManager.impact(.medium)
                    viewModel.showCreateGoal = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .heavy))
                        Text("Add Goal")
                            .font(.system(size: 14, weight: .heavy).width(.condensed))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(ColorTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: ColorTheme.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.bottom, 8)
            }
        }
    }
}
