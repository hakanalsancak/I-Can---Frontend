import Foundation

struct Goal: Codable, Identifiable {
    let id: String
    let goalType: String
    var title: String
    var description: String?
    var targetValue: Int?
    var currentValue: Int?
    var isCompleted: Bool
    var startDate: String?
    var endDate: String?
    var createdAt: String?
    var autoProgress: Int?

    var goalTypeDisplay: String {
        switch goalType {
        case "weekly": return "Weekly"
        case "monthly": return "Monthly"
        case "yearly": return "Yearly"
        default: return goalType.capitalized
        }
    }

    var goalTypeIcon: String {
        switch goalType {
        case "weekly": return "calendar"
        case "monthly": return "calendar.circle"
        case "yearly": return "star.circle"
        default: return "target"
        }
    }

    var hasTarget: Bool { targetValue != nil && (targetValue ?? 0) > 0 }

    var progressValue: Int {
        autoProgress ?? currentValue ?? 0
    }

    var progressFraction: Double {
        guard let target = targetValue, target > 0 else { return 0 }
        return min(1.0, Double(progressValue) / Double(target))
    }

    var isAutoCompleted: Bool {
        guard let target = targetValue, target > 0 else { return false }
        return progressValue >= target
    }
}

struct GoalsResponse: Codable {
    let goals: [Goal]
}

struct CreateGoalRequest: Encodable {
    let goalType: String
    let title: String
    let description: String?
    let targetValue: Int?
    let startDate: String?
    let endDate: String?
}

struct UpdateGoalRequest: Encodable {
    let title: String?
    let description: String?
    let targetValue: Int?
    let currentValue: Int?
    let isCompleted: Bool?
}
