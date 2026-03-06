import Foundation

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
    let createdAt: String?

    var date: Date? {
        Date.fromAPIString(entryDate)
    }

    var activityTypeDisplay: String {
        switch activityType {
        case "training": return "Training"
        case "game": return "Game"
        case "rest_day": return "Rest Day"
        default: return activityType.capitalized
        }
    }

    var activityIcon: String {
        switch activityType {
        case "training": return "figure.run"
        case "game": return "trophy"
        case "rest_day": return "bed.double"
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
}

struct EntrySubmitResponse: Codable {
    let entry: DailyEntry
    let streak: StreakInfo
}

struct EntriesResponse: Codable {
    let entries: [DailyEntry]
}
