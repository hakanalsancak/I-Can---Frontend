import Foundation

@Observable
final class ReportsViewModel {
    var periodStatus: PeriodStatus?
    var weeklyReports: [AIReport] = []
    var monthlyReports: [AIReport] = []
    var yearlyReports: [AIReport] = []
    var selectedReport: AIReport?
    var isLoading = false
    var errorMessage: String?
    var showPaywall = false

    var isStatusLoading: Bool {
        periodStatus == nil && !hasFailedStatus
    }

    private var hasFailedStatus = false

    func loadAll() async {
        async let s: () = loadStatus()
        async let r: () = loadReports()
        _ = await (s, r)
    }

    func loadStatus() async {
        hasFailedStatus = false
        do {
            periodStatus = try await ReportService.shared.getStatus()
        } catch {
            if periodStatus == nil { hasFailedStatus = true }
        }
    }

    func loadReports() async {
        if weeklyReports.isEmpty && monthlyReports.isEmpty && yearlyReports.isEmpty {
            isLoading = true
        }
        do {
            let all = try await ReportService.shared.getReports()
            weeklyReports = all.filter { $0.reportType == "weekly" }
            monthlyReports = all.filter { $0.reportType == "monthly" }
            yearlyReports = all.filter { $0.reportType == "yearly" }
        } catch {
            // Keep existing data on error
        }
        isLoading = false
    }

    func loadReportDetail(_ report: AIReport) async {
        do {
            selectedReport = try await ReportService.shared.getReport(id: report.id)
            AnalyticsManager.log("\(report.reportType)_report_viewed", parameters: ["report_id": report.id])
        } catch let error as APIError {
            if case .premiumRequired = error {
                showPaywall = true
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}
