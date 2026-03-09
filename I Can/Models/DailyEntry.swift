import Foundation

struct EntryResponses: Codable {
    var focusLabel: String?
    var effortLabel: String?
    var workedOn: [String]?
    var preGameFeeling: String?
    var overallPerformance: String?
    var strongestAreas: [String]?
    var recoveryQuality: String?
    var restActivities: [String]?
    var discipline: String?
    var recoveryReflection: String?
    var rotatingQ: String?
    var rotatingA: String?
    var otherActivities: [String]?
    var otherFeeling: String?
    var otherDescription: String?
}

struct DailyEntry: Codable, Identifiable {
    let id: String
    let entryDate: String
    let activityType: String
    let focusRating: Int
    let effortRating: Int
    let confidenceRating: Int
    let performanceScore: Int
    let didWell: String?
    let improveNext: String?
    let rotatingQuestionId: Int?
    let rotatingAnswer: String?
    let responses: EntryResponses?
    let createdAt: String?

    var date: Date? {
        Date.fromAPIString(entryDate)
    }

    var activityTypeDisplay: String {
        switch activityType {
        case "training": return "Training"
        case "game": return "Game"
        case "rest_day": return "Rest Day"
        case "other": return "Mixed Day"
        default: return activityType.capitalized
        }
    }

    var activityIcon: String {
        switch activityType {
        case "training": return "figure.run"
        case "game": return "trophy"
        case "rest_day": return "bed.double"
        case "other": return "ellipsis.circle"
        default: return "questionmark"
        }
    }
}

struct EntrySubmitRequest: Encodable {
    let entryDate: String
    let activityType: String
    let focusRating: Int
    let effortRating: Int
    let confidenceRating: Int
    let didWell: String?
    let improveNext: String?
    let rotatingQuestionId: Int?
    let rotatingAnswer: String?
    let responses: EntryResponses?
}

struct EntrySubmitResponse: Codable {
    let entry: DailyEntry
    let streak: StreakInfo
}

struct EntriesResponse: Codable {
    let entries: [DailyEntry]
}

struct InsightRequest: Encodable {
    let activityType: String
    var focus: String?
    var effort: String?
    var trainingAreas: [String]?
    var reflectionPositive: String?
    var reflectionImprove: String?
    var dailyQuestion: String?
    var dailyAnswer: String?
    var preGameFeeling: String?
    var overallPerformance: String?
    var strongestAreas: [String]?
    var recoveryQuality: String?
    var restActivities: [String]?
    var discipline: String?
    var recoveryReflection: String?
    var otherActivities: [String]?
    var otherFeeling: String?
    var otherDescription: String?
}

struct InsightResponse: Codable {
    let insight: String
}
