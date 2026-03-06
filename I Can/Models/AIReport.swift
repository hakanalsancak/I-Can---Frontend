import Foundation

struct AIReport: Codable, Identifiable {
    let id: String
    let reportType: String
    let periodStart: String
    let periodEnd: String
    let content: ReportContent?
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
        case "weekly": return "chart.bar"
        case "monthly": return "chart.line.uptrend.xyaxis"
        case "yearly": return "star.fill"
        default: return "doc.text"
        }
    }
}

struct ReportContent: Codable {
    let summary: String?
    let strengths: [String]?
    let areasForImprovement: [String]?
    let mentalPatterns: String?
    let consistencyAnalysis: String?
    let goalProgress: [GoalProgressItem]?
    let actionableTips: [String]?
    let motivationalMessage: String?
}

struct GoalProgressItem: Codable {
    let goal: String?
    let analysis: String?
    let recommendation: String?
}

struct ReportsResponse: Codable {
    let reports: [AIReport]
}

struct GenerateReportRequest: Encodable {
    let reportType: String
    let periodStart: String
    let periodEnd: String
}
