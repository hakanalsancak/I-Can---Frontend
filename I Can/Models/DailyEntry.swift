import Foundation

struct EntryResponses: Codable {
    // V2 Daily Log fields
    var version: Int?
    var training: TrainingData?
    var nutrition: NutritionData?
    var sleep: SleepData?
    var completedSections: [String]?

    // V1 Training
    var workedOn: [String]?
    var skillImproved: String?
    var hardestDrill: String?
    var commonMistake: String?
    var tomorrowFocus: String?

    // V1 Game stats (sport-specific)
    var gameStats: [String: Int]?
    var bestMoment: String?
    var biggestMistake: String?
    var improveNextGame: String?

    // V1 Rest day
    var recoveryActivities: [String]?
    var sportStudy: String?
    var restTomorrowFocus: String?

    // Universal
    var didWell: String?
    var improveNext: String?
    var proudMoment: String?

    // Legacy fields (backward compatibility with old entries)
    var focusLabel: String?
    var effortLabel: String?
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
    let responses: EntryResponses?
    let createdAt: String?

    var date: Date? {
        Date.fromAPIString(entryDate)
    }
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
    var trainingAreas: [String]?
    var skillImproved: String?
    var hardestDrill: String?
    var commonMistake: String?
    var tomorrowFocus: String?
    var gameStats: [String: Int]?
    var bestMoment: String?
    var biggestMistake: String?
    var improveNextGame: String?
    var recoveryActivities: [String]?
    var sportStudy: String?
    var restTomorrowFocus: String?
    var reflectionPositive: String?
    var reflectionImprove: String?
    var proudMoment: String?

    // V2 Training Log fields
    var trainingSessions: [TrainingSessionInsight]?
    var sessionScore: Int?

    // Nutrition Log fields
    var nutrition: NutritionInsight?
}

struct NutritionInsight: Encodable {
    var breakfast: String?
    var lunch: String?
    var dinner: String?
    var snacks: String?
    var drinks: String?
    var healthScore: Int?
    var mealsLogged: Int?
}

struct TrainingSessionInsight: Encodable {
    let trainingType: String
    var duration: Int?
    var matchType: String?
    var result: String?
    var performanceRating: Int?
    var minutesPlayed: Int?
    var position: String?
    var keyStats: [String: Int]?
    var gymFocus: String?
    var effortLevel: String?
    var exercises: [String]?
    var cardioType: String?
    var distance: Double?
    var pace: String?
    var cardioEffort: String?
    var skillTrained: String?
    var focusQuality: String?
    var tacticalType: String?
    var understandingLevel: String?
    var recoveryType: String?
    var sessionScore: Int?
    var notes: String?
}

struct InsightResponse: Codable {
    let insight: String
}
