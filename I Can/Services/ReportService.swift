import Foundation

@Observable
final class ReportService {
    static let shared = ReportService()

    func getReports() async throws -> [AIReport] {
        let response: ReportsResponse = try await APIClient.shared.request(APIEndpoints.Reports.base)
        return response.reports
    }

    func getReport(id: String) async throws -> AIReport {
        try await APIClient.shared.request(APIEndpoints.Reports.byId(id))
    }

    func generateReport(type: String) async throws -> AIReport {
        let request = GenerateReportRequest(reportType: type)
        return try await APIClient.shared.request(
            APIEndpoints.Reports.generate, method: "POST", body: request
        )
    }

    func checkEligibility(type: String) async throws -> GenerateEligibility {
        let endpoint = APIEndpoints.Reports.canGenerate + "?reportType=\(type)"
        return try await APIClient.shared.request(endpoint)
    }

    private init() {}
}
