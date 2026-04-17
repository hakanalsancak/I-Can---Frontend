import Foundation

// MARK: - Analytics Response

struct AnalyticsSessionData: Codable {
    let type: String
    let duration: Int
    let intensity: String
    let sessionScore: Int?
    let result: String?
    let winMethod: String?
    let performanceRating: Int?
    let minutesPlayed: Int?
    let position: String?
    let keyStats: [String: Int]?
    let gymFocus: String?
    let effortLevel: String?
    let exercises: [String]?
    let cardioType: String?
    let distance: Double?
    let distanceUnit: String?
    let steps: Int?
    let pace: String?
    let cardioEffort: String?
    let skillTrained: String?
    let focusQuality: String?
    let tacticalType: String?
    let understandingLevel: String?
    let recoveryType: String?
    let notes: String?
}

struct AnalyticsNutritionDetail: Codable {
    let mealsLogged: Int
    let breakfast: Bool
    let lunch: Bool
    let dinner: Bool
    let snacks: Bool
    let drinks: Bool
    let healthScore: Int
    let breakfastText: String?
    let lunchText: String?
    let dinnerText: String?
    let snacksText: String?
    let drinksText: String?
}

struct AnalyticsDailyData: Codable, Identifiable, Equatable {
    static func == (lhs: AnalyticsDailyData, rhs: AnalyticsDailyData) -> Bool {
        lhs.date == rhs.date
    }

    var id: String { date }
    let date: String
    let completion: Int
    let training: Bool
    let nutrition: Bool
    let sleep: Bool
    let sleepHours: Double?
    let sleepTime: String?
    let wakeTime: String?
    let trainingSessions: [AnalyticsSessionData]?
    let trainingDuration: Int?
    let nutritionDetail: AnalyticsNutritionDetail?
}

struct AnalyticsTrainingSummary: Codable {
    let totalSessions: Int
    let totalDuration: Int
    let avgDuration: Int
    let typeBreakdown: [String: Int]
    let intensityBreakdown: [String: Int]
}

struct AnalyticsNutritionSummary: Codable {
    let daysLogged: Int
    let avgMealsPerDay: Double
    let avgHealthScore: Int
    let breakfastRate: Int
    let lunchRate: Int
    let dinnerRate: Int
    let snacksRate: Int
    let drinksRate: Int
}

struct AnalyticsResponse: Codable {
    let period: String
    let startDate: String
    let endDate: String
    let totalDays: Int
    let expectedDays: Int
    let trainingSessions: Int
    let nutritionDays: Int
    let sleepDays: Int
    let avgSleepHours: Double?
    let avgCompletion: Int
    let consistencyPercent: Int
    let trainingSummary: AnalyticsTrainingSummary?
    let nutritionSummary: AnalyticsNutritionSummary?
    let dailyData: [AnalyticsDailyData]
}

@MainActor
@Observable
final class DailyLogService {
    static let shared = DailyLogService()

    func submitDailyLog(
        date: String,
        training: TrainingData?,
        nutrition: NutritionData?,
        sleep: SleepData?,
        completedSections: [String]
    ) async throws -> EntrySubmitResponse {
        let request = DailyLogSubmitRequest(
            entryDate: date,
            responses: DailyLogSubmitResponses(
                training: training,
                nutrition: nutrition,
                sleep: sleep,
                completedSections: completedSections
            )
        )

        return try await APIClient.shared.request(
            APIEndpoints.Entries.base, method: "POST", body: request
        )
    }

    func getAnalytics(period: String = "week") async throws -> AnalyticsResponse {
        try await APIClient.shared.request(
            APIEndpoints.Entries.analytics + "?period=\(period)"
        )
    }

    func getTodayLog() async throws -> DailyEntry {
        try await EntryService.shared.getEntry(date: Date().apiDateString)
    }

    private init() {}
}
