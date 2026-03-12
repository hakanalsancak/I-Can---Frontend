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
        case "yearly": return "Yearly Report"
        default: return reportType.capitalized
        }
    }

    var reportIcon: String {
        switch reportType {
        case "weekly": return "chart.bar.fill"
        case "monthly": return "chart.line.uptrend.xyaxis"
        case "yearly": return "star.fill"
        default: return "doc.text"
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

    var resolvedGrowthAreas: [GrowthAreaItem]? {
        growthAreas ?? goalProgress
    }
}

struct GrowthAreaItem: Codable {
    let area: String?
    let goal: String?
    let analysis: String?
    let recommendation: String?

    var title: String? { area ?? goal }
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
    let yearly: PeriodInfo
}
