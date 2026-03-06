import Foundation

@Observable
final class ReportsViewModel {
    var reports: [AIReport] = []
    var selectedReport: AIReport?
    var isLoading = false
    var isGenerating = false
    var selectedType: String = "weekly"
    var errorMessage: String?
    var showPaywall = false

    func loadReports() async {
        isLoading = true
        do {
            reports = try await ReportService.shared.getReports(type: selectedType)
        } catch {
            reports = []
        }
        isLoading = false
    }

    func generateReport() async {
        let isPremium = SubscriptionService.shared.isPremium
        if !isPremium {
            showPaywall = true
            return
        }

        isGenerating = true
        errorMessage = nil

        let now = Date()
        let periodStart: Date
        let periodEnd = now

        switch selectedType {
        case "weekly": periodStart = now.daysAgo(7)
        case "monthly": periodStart = now.monthsAgo(1)
        case "yearly": periodStart = now.monthsAgo(12)
        default: periodStart = now.daysAgo(7)
        }

        do {
            let report = try await ReportService.shared.generateReport(
                type: selectedType,
                periodStart: periodStart.apiDateString,
                periodEnd: periodEnd.apiDateString
            )
            reports.insert(report, at: 0)
            selectedReport = report
            HapticManager.notification(.success)
        } catch let error as APIError {
            if case .premiumRequired = error {
                showPaywall = true
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
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
