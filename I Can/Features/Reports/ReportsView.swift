import SwiftUI

struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    typePicker

                    generateButton

                    if viewModel.isLoading {
                        LoadingView(message: "Loading reports...")
                    } else if viewModel.reports.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.reports) { report in
                            Button {
                                Task { await viewModel.loadReportDetail(report) }
                            } label: {
                                reportRow(report)
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Typography.footnote)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("AI Reports")
            .task { await viewModel.loadReports() }
            .onChange(of: viewModel.selectedType) { _, _ in
                Task { await viewModel.loadReports() }
            }
            .sheet(item: $viewModel.selectedReport) { report in
                ReportDetailView(report: report)
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                SubscriptionView()
            }
        }
    }

    private var typePicker: some View {
        HStack(spacing: 8) {
            ForEach(["weekly", "monthly", "yearly"], id: \.self) { type in
                Button {
                    HapticManager.selection()
                    viewModel.selectedType = type
                } label: {
                    Text(type.capitalized)
                        .font(Typography.subheadline)
                        .foregroundColor(viewModel.selectedType == type ? .white : ColorTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewModel.selectedType == type ? ColorTheme.accent : ColorTheme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var generateButton: some View {
        PrimaryButton(
            title: "Generate \(viewModel.selectedType.capitalized) Report",
            isLoading: viewModel.isGenerating
        ) {
            Task { await viewModel.generateReport() }
        }
    }

    private func reportRow(_ report: AIReport) -> some View {
        CardView {
            HStack(spacing: 12) {
                Image(systemName: report.reportIcon)
                    .font(.title2)
                    .foregroundColor(ColorTheme.accent)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(report.reportTypeDisplay)
                        .font(Typography.headline)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    if let start = Date.fromAPIString(report.periodStart),
                       let end = Date.fromAPIString(report.periodEnd) {
                        Text("\(start.shortDisplayString) - \(end.shortDisplayString)")
                            .font(Typography.caption)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Text("No Reports Yet")
                .font(Typography.title3)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Text("Generate your first AI performance\nreport to get coaching insights")
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}
