import SwiftUI

struct GoalsView: View {
    @State private var viewModel = GoalsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Goals") {
                    Button {
                        viewModel.showCreateGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                            .frame(width: 32, height: 32)
                            .background(ColorTheme.subtleAccent(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        filterRow

                        if !viewModel.weeklyGoals.isEmpty || viewModel.selectedFilter == nil || viewModel.selectedFilter == "weekly" {
                            goalSection(title: "WEEKLY GOALS", goals: viewModel.weeklyGoals)
                        }
                        if !viewModel.monthlyGoals.isEmpty || viewModel.selectedFilter == nil || viewModel.selectedFilter == "monthly" {
                            goalSection(title: "MONTHLY GOALS", goals: viewModel.monthlyGoals)
                        }
                        if !viewModel.yearlyGoals.isEmpty || viewModel.selectedFilter == nil || viewModel.selectedFilter == "yearly" {
                            goalSection(title: "YEARLY GOALS", goals: viewModel.yearlyGoals)
                        }

                        if viewModel.goals.isEmpty && !viewModel.isLoading {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showCreateGoal) {
                GoalFormView { type, title, description in
                    Task { await viewModel.createGoal(type: type, title: title, description: description) }
                }
            }
            .task { await viewModel.loadGoals() }
            .refreshable { await viewModel.loadGoals() }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            ForEach([
                (nil as String?, "All"),
                ("weekly" as String?, "Weekly"),
                ("monthly" as String?, "Monthly"),
                ("yearly" as String?, "Yearly"),
            ], id: \.1) { filter in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedFilter = filter.0
                    }
                } label: {
                    Text(filter.1)
                        .font(Typography.subheadline)
                        .foregroundColor(viewModel.selectedFilter == filter.0 ? .white : ColorTheme.primaryText(colorScheme))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedFilter == filter.0
                            ? AnyShapeStyle(ColorTheme.accentGradient)
                            : AnyShapeStyle(ColorTheme.cardBackground(colorScheme))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                }
            }
            Spacer()
        }
    }

    private func goalSection(title: String, goals: [Goal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .sectionHeader(colorScheme)

            if goals.isEmpty {
                Text("No goals set yet")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
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
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 36).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
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
        HStack(spacing: 14) {
            Button(action: {
                HapticManager.impact(.light)
                onToggle()
            }) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22).width(.condensed))
                    .foregroundColor(goal.isCompleted ? Color(hex: "22C55E") : ColorTheme.tertiaryText(colorScheme))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(Typography.body)
                    .foregroundColor(
                        goal.isCompleted
                        ? ColorTheme.secondaryText(colorScheme)
                        : ColorTheme.primaryText(colorScheme)
                    )
                    .strikethrough(goal.isCompleted)
                if let desc = goal.description, !desc.isEmpty {
                    Text(desc)
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
