import Foundation

@Observable
final class GoalsViewModel {
    var goals: [Goal] = []
    var selectedFilter: String? = nil
    var showCreateGoal = false
    var isLoading = false

    var filteredGoals: [Goal] {
        guard let filter = selectedFilter else { return goals }
        return goals.filter { $0.goalType == filter }
    }

    var weeklyGoals: [Goal] { goals.filter { $0.goalType == "weekly" } }
    var monthlyGoals: [Goal] { goals.filter { $0.goalType == "monthly" } }
    var yearlyGoals: [Goal] { goals.filter { $0.goalType == "yearly" } }

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
        } catch {
            // Handle error
        }
    }

    func toggleComplete(_ goal: Goal) async {
        do {
            let request = UpdateGoalRequest(
                title: nil, description: nil,
                targetValue: nil, currentValue: nil,
                isCompleted: !goal.isCompleted
            )
            let updated = try await GoalService.shared.updateGoal(id: goal.id, request)
            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = updated
            }
            HapticManager.notification(.success)
        } catch {
            // Handle error
        }
    }

    func deleteGoal(_ goal: Goal) async {
        do {
            try await GoalService.shared.deleteGoal(id: goal.id)
            goals.removeAll { $0.id == goal.id }
        } catch {
            // Handle error
        }
    }
}
