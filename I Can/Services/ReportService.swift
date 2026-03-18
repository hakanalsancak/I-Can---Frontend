import Foundation

@MainActor
@Observable
final class ReportService {
    static let shared = ReportService()

    func getStatus() async throws -> PeriodStatus {
        try await APIClient.shared.request(APIEndpoints.Reports.status)
    }

    func getReports() async throws -> [AIReport] {
        let response: ReportsResponse = try await APIClient.shared.request(APIEndpoints.Reports.base)
        return response.reports
    }

    func getReport(id: String) async throws -> AIReport {
        try await APIClient.shared.request(APIEndpoints.Reports.byId(id))
    }

    private init() {}
}
