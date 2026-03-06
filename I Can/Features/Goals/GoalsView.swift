import SwiftUI

struct GoalsView: View {
    @State private var viewModel = GoalsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    filterPills

                    if !viewModel.weeklyGoals.isEmpty || viewModel.selectedFilter == nil || viewModel.selectedFilter == "weekly" {
                        goalSection(title: "Weekly Goals", icon: "calendar", goals: viewModel.weeklyGoals)
                    }
                    if !viewModel.monthlyGoals.isEmpty || viewModel.selectedFilter == nil || viewModel.selectedFilter == "monthly" {
                        goalSection(title: "Monthly Goals", icon: "calendar.circle", goals: viewModel.monthlyGoals)
                    }
                    if !viewModel.yearlyGoals.isEmpty || viewModel.selectedFilter == nil || viewModel.selectedFilter == "yearly" {
                        goalSection(title: "Yearly Goals", icon: "star.circle", goals: viewModel.yearlyGoals)
                    }

                    if viewModel.goals.isEmpty && !viewModel.isLoading {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(ColorTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateGoal) {
                GoalFormView { type, title, description in
                    Task { await viewModel.createGoal(type: type, title: title, description: description) }
                }
            }
            .task { await viewModel.loadGoals() }
            .refreshable { await viewModel.loadGoals() }
        }
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "All", isSelected: viewModel.selectedFilter == nil) {
                    viewModel.selectedFilter = nil
                }
                FilterPill(title: "Weekly", isSelected: viewModel.selectedFilter == "weekly") {
                    viewModel.selectedFilter = "weekly"
                }
                FilterPill(title: "Monthly", isSelected: viewModel.selectedFilter == "monthly") {
                    viewModel.selectedFilter = "monthly"
                }
                FilterPill(title: "Yearly", isSelected: viewModel.selectedFilter == "yearly") {
                    viewModel.selectedFilter = "yearly"
                }
            }
        }
    }

    private func goalSection(title: String, icon: String, goals: [Goal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(Typography.headline)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            if goals.isEmpty {
                Text("No \(title.lowercased()) set yet")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(goals) { goal in
                    GoalRow(goal: goal, colorScheme: colorScheme) {
                        Task { await viewModel.toggleComplete(goal) }
                    } onDelete: {
                        Task { await viewModel.deleteGoal(goal) }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text("Set Your First Goal")
                .font(Typography.title3)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text("Create weekly, monthly, or yearly\ngoals to track your progress")
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

private struct GoalRow: View {
    let goal: Goal
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(goal.isCompleted ? .green : ColorTheme.secondaryText(colorScheme))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .strikethrough(goal.isCompleted)
                if let desc = goal.description, !desc.isEmpty {
                    Text(desc)
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            Text(title)
                .font(Typography.subheadline)
                .foregroundColor(isSelected ? .white : ColorTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ColorTheme.accent : ColorTheme.accent.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}
