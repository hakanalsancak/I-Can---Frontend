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
