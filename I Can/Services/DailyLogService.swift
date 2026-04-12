import Foundation

// MARK: - Analytics Response

struct AnalyticsSessionData: Codable {
    let type: String
    let duration: Int
    let intensity: String
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
        // Compute ratings based on completion
        let sectionCount = completedSections.count
        let baseRating = max(3, sectionCount * 3)

        var focus = baseRating
        var effort = baseRating
        var confidence = baseRating

        if let t = training {
            let intensityBonus: Int
            switch t.highestIntensity {
            case "high": intensityBonus = 2
            case "max": intensityBonus = 3
            case "medium": intensityBonus = 1
            default: intensityBonus = 0
            }
            let durationBonus = min(t.totalDuration / 30, 2)
            let sessionBonus = min(t.sessionCount - 1, 1)
            focus = min(focus + intensityBonus + durationBonus + sessionBonus, 9)
            effort = min(effort + intensityBonus + durationBonus + sessionBonus + 1, 9)
        }

        if let s = sleep {
            let hours = s.durationHours
            if hours >= 7 && hours <= 9 {
                confidence = min(confidence + 2, 9)
            } else if hours >= 6 {
                confidence = min(confidence + 1, 9)
            }
        }

        if nutrition != nil {
            focus = min(focus + 1, 9)
        }

        let responses = DailyLogSubmitResponses(
            training: training,
            nutrition: nutrition,
            sleep: sleep,
            completedSections: completedSections
        )

        let request = DailyLogSubmitRequest(
            entryDate: date,
            focusRating: max(focus, 3),
            effortRating: max(effort, 3),
            confidenceRating: max(confidence, 3),
            responses: responses
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
