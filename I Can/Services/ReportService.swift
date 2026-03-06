import Foundation

@Observable
final class ReportService {
    static let shared = ReportService()

    func getReports(type: String? = nil) async throws -> [AIReport] {
        var endpoint = APIEndpoints.Reports.base
        if let type { endpoint += "?type=\(type)" }
        let response: ReportsResponse = try await APIClient.shared.request(endpoint)
        return response.reports
    }

    func getReport(id: String) async throws -> AIReport {
        try await APIClient.shared.request(APIEndpoints.Reports.byId(id))
    }

    func generateReport(type: String, periodStart: String, periodEnd: String) async throws -> AIReport {
        let request = GenerateReportRequest(reportType: type, periodStart: periodStart, periodEnd: periodEnd)
        return try await APIClient.shared.request(
            APIEndpoints.Reports.generate, method: "POST", body: request
        )
    }

    private init() {}
}
