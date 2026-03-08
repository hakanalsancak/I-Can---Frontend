import Foundation

@Observable
final class GoalsViewModel {
    var goals: [Goal] = []
    var selectedFilter: String? = nil
    var showCreateGoal = false
    var isLoading = false
    var justCompleted: String? = nil

    var filteredGoals: [Goal] {
        guard let filter = selectedFilter else { return goals }
        return goals.filter { $0.goalType == filter }
    }

    var weeklyGoals: [Goal] { filteredGoals.filter { $0.goalType == "weekly" } }
    var monthlyGoals: [Goal] { filteredGoals.filter { $0.goalType == "monthly" } }
    var yearlyGoals: [Goal] { filteredGoals.filter { $0.goalType == "yearly" } }

    var weeklyCount: Int { goals.filter { $0.goalType == "weekly" }.count }
    var monthlyCount: Int { goals.filter { $0.goalType == "monthly" }.count }
    var yearlyCount: Int { goals.filter { $0.goalType == "yearly" }.count }

    var activeGoals: [Goal] { goals.filter { !$0.isCompleted } }
    var completedGoals: [Goal] { goals.filter { $0.isCompleted } }

    func loadGoals() async {
        isLoading = true
        do {
            goals = try await GoalService.shared.getGoals()
        } catch {
            goals = []
        }
        isLoading = false
    }

    func createGoal(type: String, title: String, description: String?) async {
        do {
            let request = CreateGoalRequest(
                goalType: type, title: title, description: description,
                targetValue: nil, startDate: nil, endDate: nil
            )
            let goal = try await GoalService.shared.createGoal(request)
            goals.insert(goal, at: 0)
            HapticManager.notification(.success)
        } catch {}
    }

    func toggleComplete(_ goal: Goal) async {
        let newCompleted = !goal.isCompleted
        do {
            let request = UpdateGoalRequest(
                title: nil, description: nil,
                targetValue: nil, currentValue: nil,
                isCompleted: newCompleted
            )
            let updated = try await GoalService.shared.updateGoal(id: goal.id, request)
            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = updated
            }
            if newCompleted {
                justCompleted = goal.id
                HapticManager.notification(.success)
                try? await Task.sleep(for: .seconds(2))
                justCompleted = nil
            } else {
                HapticManager.impact(.light)
            }
        } catch {}
    }

    func deleteGoal(_ goal: Goal) async {
        do {
            try await GoalService.shared.deleteGoal(id: goal.id)
            goals.removeAll { $0.id == goal.id }
            HapticManager.impact(.medium)
        } catch {}
    }
}
