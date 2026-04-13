import SwiftUI

struct SavedReportsView: View {
    let weeklyReports: [AIReport]
    let monthlyReports: [AIReport]
    let yearlyReports: [AIReport]
    let onSelectReport: (AIReport) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Saved Reports")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if weeklyReports.isEmpty && monthlyReports.isEmpty && yearlyReports.isEmpty {
                            emptyState
                        } else {
                            if !weeklyReports.isEmpty {
                                reportGroup(
                                    title: "WEEKLY REPORTS",
                                    icon: "chart.bar.fill",
                                    iconColor: Color(hex: "8B5CF6"),
                                    reports: weeklyReports
                                )
                            }

                            if !monthlyReports.isEmpty {
                                reportGroup(
                                    title: "MONTHLY REPORTS",
                                    icon: "chart.line.uptrend.xyaxis",
                                    iconColor: Color(hex: "2563EB"),
                                    reports: monthlyReports
                                )
                            }

                            if !yearlyReports.isEmpty {
                                reportGroup(
                                    title: "YEARLY REPORTS",
                                    icon: "star.fill",
                                    iconColor: Color(hex: "F59E0B"),
                                    reports: yearlyReports
                                )
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

    // MARK: - Report Group

    private func reportGroup(
        title: String,
        icon: String,
        iconColor: Color,
        reports: [AIReport]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .sectionHeader(colorScheme)
                Spacer()
                Text("\(reports.count)")
                    .font(.system(size: 13, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(Capsule())
            }

            VStack(spacing: 10) {
                ForEach(reports) { report in
                    Button {
                        HapticManager.selection()
                        Task { await onSelectReport(report) }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: report.reportIcon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(iconColor)
                                .frame(width: 32, height: 32)
                                .background(iconColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(report.dateRangeDisplay)
                                    .font(.system(size: 15, weight: .semibold).width(.condensed))
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                                HStack(spacing: 8) {
                                    if let created = report.createdDateDisplay {
                                        Text("Generated \(created)")
                                            .font(.system(size: 12, weight: .medium).width(.condensed))
                                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                    }
                                    if let count = report.entryCount {
                                        Text("·  \(count) entries")
                                            .font(.system(size: 12, weight: .medium).width(.condensed))
                                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        }
                        .padding(14)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))

            Text("No Saved Reports Yet")
                .font(.system(size: 18, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text("Your completed reports will appear here. Keep logging your daily entries to generate reports.")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
