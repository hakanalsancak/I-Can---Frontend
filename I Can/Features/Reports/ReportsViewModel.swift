import Foundation

@MainActor
@Observable
final class ReportsViewModel {
    var periodStatus: PeriodStatus?
    var weeklyReports: [AIReport] = []
    var monthlyReports: [AIReport] = []
    var selectedReport: AIReport?
    var isLoading = false
    var errorMessage: String?
    var showPaywall = false

    var isStatusLoading: Bool {
        periodStatus == nil && !hasFailedStatus
    }

    private var hasFailedStatus = false

    var weeklyHero: AIReport? { weeklyReports.first }
    var monthlyHero: AIReport? { monthlyReports.first }

    func recentScores(for type: String, limit: Int = 4) -> [AIReport] {
        let source = type == "weekly" ? weeklyReports : monthlyReports
        return Array(source.prefix(limit))
    }

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
            hasFailedStatus = true
        }
    }

    func loadReports() async {
        if weeklyReports.isEmpty && monthlyReports.isEmpty {
            isLoading = true
        }
        do {
            let all = try await ReportService.shared.getReports()
            weeklyReports = all.filter { $0.reportType == "weekly" }
            monthlyReports = all.filter { $0.reportType == "monthly" }
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

    func openReport(byId id: String) async {
        // Used by push deep-link: we don't yet know the type/dates, so issue
        // a detail fetch and let the API hydrate the AIReport.
        let stub = AIReport(
            id: id,
            reportType: "weekly",
            periodStart: "",
            periodEnd: "",
            content: nil,
            entryCount: nil,
            createdAt: nil
        )
        await loadReportDetail(stub)
    }
}
