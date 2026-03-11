import Foundation

@Observable
final class ReportsViewModel {
    var periodStatus: PeriodStatus?
    var weeklyReports: [AIReport] = []
    var monthlyReports: [AIReport] = []
    var yearlyReports: [AIReport] = []
    var selectedReport: AIReport?
    var isLoading = false
    var isStatusLoading = false
    var errorMessage: String?
    var showPaywall = false

    func loadAll() async {
        async let s: () = loadStatus()
        async let r: () = loadReports()
        _ = await (s, r)
    }

    func loadStatus() async {
        isStatusLoading = true
        do {
            periodStatus = try await ReportService.shared.getStatus()
        } catch {
            periodStatus = nil
        }
        isStatusLoading = false
    }

    func loadReports() async {
        isLoading = true
        do {
            let all = try await ReportService.shared.getReports()
            weeklyReports = all.filter { $0.reportType == "weekly" }
            monthlyReports = all.filter { $0.reportType == "monthly" }
            yearlyReports = all.filter { $0.reportType == "yearly" }
        } catch {
            weeklyReports = []
            monthlyReports = []
            yearlyReports = []
        }
        isLoading = false
    }

    func loadReportDetail(_ report: AIReport) async {
        do {
            selectedReport = try await ReportService.shared.getReport(id: report.id)
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
