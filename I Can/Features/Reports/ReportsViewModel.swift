import Foundation

@Observable
final class ReportsViewModel {
    var weeklyReports: [AIReport] = []
    var monthlyReports: [AIReport] = []
    var selectedReport: AIReport?
    var isLoading = false
    var isGenerating = false
    var errorMessage: String?
    var showPaywall = false

    var weeklyEligibility: GenerateEligibility?
    var monthlyEligibility: GenerateEligibility?
    var generationSuccessType: String?

    func loadReports() async {
        isLoading = true
        do {
            let all = try await ReportService.shared.getReports()
            weeklyReports = all.filter { $0.reportType == "weekly" }
            monthlyReports = all.filter { $0.reportType == "monthly" }
        } catch {
            weeklyReports = []
            monthlyReports = []
        }
        isLoading = false
    }

    func checkEligibility() async {
        async let w = ReportService.shared.checkEligibility(type: "weekly")
        async let m = ReportService.shared.checkEligibility(type: "monthly")
        weeklyEligibility = try? await w
        monthlyEligibility = try? await m
    }

    func generateReport(type: String) async {
        let isPremium = SubscriptionService.shared.isPremium
        if !isPremium {
            showPaywall = true
            return
        }

        isGenerating = true
        errorMessage = nil
        generationSuccessType = nil

        do {
            let report = try await ReportService.shared.generateReport(type: type)
            if report.alreadyExists == true {
                errorMessage = "You already generated a \(type) report for this period"
            } else {
                if type == "weekly" {
                    weeklyReports.insert(report, at: 0)
                } else {
                    monthlyReports.insert(report, at: 0)
                }
                generationSuccessType = type
                selectedReport = report
                HapticManager.notification(.success)
            }
            await checkEligibility()
        } catch let error as APIError {
            switch error {
            case .premiumRequired:
                showPaywall = true
            case .serverError(let msg):
                errorMessage = msg
            default:
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
