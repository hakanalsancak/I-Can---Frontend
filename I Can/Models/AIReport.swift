import Foundation

struct AIReport: Codable, Identifiable {
    let id: String
    let reportType: String
    let periodStart: String
    let periodEnd: String
    let content: ReportContent?
    let entryCount: Int?
    let createdAt: String?

    var reportTypeDisplay: String {
        switch reportType {
        case "weekly": return "Weekly Report"
        case "monthly": return "Monthly Report"
        default: return reportType.capitalized
        }
    }

    var reportIcon: String {
        switch reportType {
        case "weekly": return "chart.bar.fill"
        case "monthly": return "chart.line.uptrend.xyaxis"
        default: return "doc.text"
        }
    }

    var accentHex: String {
        switch reportType {
        case "weekly": return "8B5CF6"
        case "monthly": return "2563EB"
        default: return "8B5CF6"
        }
    }

    var dateRangeDisplay: String {
        guard let start = Date.fromAPIString(periodStart),
              let end = Date.fromAPIString(periodEnd) else {
            return "\(periodStart) – \(periodEnd)"
        }
        let startFmt = DateFormatter()
        startFmt.dateFormat = "MMM d"
        let endFmt = DateFormatter()
        let startYear = Calendar.current.component(.year, from: start)
        let endYear = Calendar.current.component(.year, from: end)
        if startYear != endYear {
            endFmt.dateFormat = "MMM d, yyyy"
        } else {
            endFmt.dateFormat = "MMM d"
        }
        return "\(startFmt.string(from: start)) – \(endFmt.string(from: end))"
    }

    var monthLabel: String {
        guard let start = Date.fromAPIString(periodStart) else { return periodStart }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: start)
    }

    var weekLabel: String {
        guard let start = Date.fromAPIString(periodStart) else { return periodStart }
        let cal = Calendar(identifier: .iso8601)
        let week = cal.component(.weekOfYear, from: start)
        return "Week \(week)"
    }

    var createdDateDisplay: String? {
        guard let createdAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: createdAt) ?? {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            return fallback.date(from: createdAt)
        }() else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: date)
    }
}

struct ReportContent: Codable {
    // Legacy prose fields — still tolerated for back-compat with reports
    // generated before the v2 schema. New UI prefers the structured fields below.
    let summary: String?
    let strengths: [String]?
    let areasForImprovement: [String]?
    let mentalPatterns: String?
    let physicalPatterns: String?
    let consistencyAnalysis: String?
    let growthAreas: [GrowthAreaItem]?
    let goalProgress: [GrowthAreaItem]?
    let actionableTips: [String]?
    let motivationalMessage: String?

    // v2 structured fields powering the paged "report card" UI
    let overallScore: Int?
    let trainingScore: Int?
    let nutritionScore: Int?
    let sleepScore: Int?
    let prevOverallScore: Int?
    let prevTrainingScore: Int?
    let prevNutritionScore: Int?
    let prevSleepScore: Int?
    let improvementPct: Double?
    let streakWeeks: Int?
    let headline: String?
    let bestDay: DayHighlight?
    let worstDay: DayHighlight?
    let dailyScores: [DailyScore]?      // weekly: 7 entries · monthly: up to 31
    let weeklyScores: [WeeklyScore]?    // monthly only: up to 5 entries
    let pillarTrend: PillarTrend?       // monthly only

    var resolvedGrowthAreas: [GrowthAreaItem]? {
        growthAreas ?? goalProgress
    }

    var primaryAction: String? {
        actionableTips?.first
    }

    var letterGrade: String {
        guard let score = overallScore else { return "—" }
        switch score {
        case 90...: return "A"
        case 80..<90: return "B+"
        case 70..<80: return "B"
        case 60..<70: return "C"
        default: return "D"
        }
    }
}

struct GrowthAreaItem: Codable {
    let area: String?
    let goal: String?
    let analysis: String?
    let recommendation: String?

    var title: String? { area ?? goal }
}

struct DayHighlight: Codable {
    let date: String
    let score: Int
    let label: String
}

struct DailyScore: Codable {
    let date: String
    let score: Int
}

struct WeeklyScore: Codable {
    let weekIndex: Int
    let score: Int
    let label: String?
}

struct PillarTrend: Codable {
    let trainingPct: Double?
    let nutritionPct: Double?
    let sleepPct: Double?
    let trainingNote: String?
    let nutritionNote: String?
    let sleepNote: String?
}

struct ReportsResponse: Codable {
    let reports: [AIReport]
}

struct PeriodInfo: Codable {
    let periodStart: String
    let periodEnd: String
    let entryCount: Int
    let requiredEntries: Int
    let daysRemaining: Int
    let reportReady: Bool
    let reportId: String?

    var dateRangeDisplay: String {
        guard let start = Date.fromAPIString(periodStart),
              let end = Date.fromAPIString(periodEnd) else {
            return "\(periodStart) – \(periodEnd)"
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let endFmt = DateFormatter()
        let startYear = Calendar.current.component(.year, from: start)
        let endYear = Calendar.current.component(.year, from: end)
        endFmt.dateFormat = startYear != endYear ? "MMM d, yyyy" : "MMM d"
        return "\(fmt.string(from: start)) – \(endFmt.string(from: end))"
    }

    var progressFraction: Double {
        guard requiredEntries > 0 else { return 0 }
        return min(Double(entryCount) / Double(requiredEntries), 1.0)
    }

    var isEligible: Bool {
        entryCount >= requiredEntries
    }
}

struct PeriodStatus: Codable {
    let weekly: PeriodInfo
    let monthly: PeriodInfo
    // `yearly` was removed but is left optional so older backends mid-deploy
    // don't fail decoding. The field is never read by the new UI.
    let yearly: PeriodInfo?
}
