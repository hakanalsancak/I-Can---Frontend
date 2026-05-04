import SwiftUI

struct SavedReportsView: View {
    let weeklyReports: [AIReport]
    let monthlyReports: [AIReport]
    let onSelectReport: (AIReport) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable {
        case all = "All"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    private var combined: [AIReport] {
        let merged: [AIReport] = (weeklyReports + monthlyReports).sorted { (a: AIReport, b: AIReport) -> Bool in
            if a.periodEnd != b.periodEnd { return a.periodEnd > b.periodEnd }
            return a.id > b.id
        }
        switch filter {
        case .all: return merged
        case .weekly: return merged.filter { $0.reportType == "weekly" }
        case .monthly: return merged.filter { $0.reportType == "monthly" }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Saved Reports")

                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        if combined.isEmpty {
                            emptyState
                        } else {
                            ForEach(combined) { report in
                                Button {
                                    HapticManager.selection()
                                    Task { await onSelectReport(report) }
                                } label: {
                                    reportRow(report)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 14)
                .padding(.trailing, 20)
            }
        }
    }

    private func reportRow(_ report: AIReport) -> some View {
        let typeColor = Color(hex: report.accentHex)
        let scoreText: String? = {
            if let s = report.content?.overallScore { return "\(s)" }
            return nil
        }()

        return HStack(spacing: 14) {
            Image(systemName: report.reportIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(typeColor)
                .frame(width: 36, height: 36)
                .background(typeColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(report.reportTypeDisplay.uppercased())
                        .font(.system(size: 10, weight: .heavy).width(.condensed))
                        .tracking(1)
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.12))
                        .clipShape(Capsule())
                    Text(report.dateRangeDisplay)
                        .font(.system(size: 14, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }

                HStack(spacing: 8) {
                    if let created = report.createdDateDisplay {
                        Text(created)
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    if let count = report.entryCount {
                        Text("· \(count) entries")
                            .font(.system(size: 12, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }

            Spacer()

            if let scoreText {
                Text(scoreText)
                    .font(.system(size: 20, weight: .heavy, design: .rounded).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .monospacedDigit()
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))

            Text("No Saved Reports Yet")
                .font(.system(size: 18, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text("Reports show up here every Monday and the 1st of the month. Keep logging.")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
