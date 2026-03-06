import SwiftUI

struct ReportDetailView: View {
    let report: AIReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let content = report.content {
                        if let summary = content.summary {
                            sectionCard(title: "Summary", icon: "doc.text") {
                                Text(summary)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                            }
                        }

                        if let strengths = content.strengths, !strengths.isEmpty {
                            sectionCard(title: "Strengths", icon: "hand.thumbsup.fill") {
                                ForEach(strengths, id: \.self) { item in
                                    bulletPoint(item, color: .green)
                                }
                            }
                        }

                        if let areas = content.areasForImprovement, !areas.isEmpty {
                            sectionCard(title: "Areas to Improve", icon: "arrow.up.circle.fill") {
                                ForEach(areas, id: \.self) { item in
                                    bulletPoint(item, color: .orange)
                                }
                            }
                        }

                        if let mental = content.mentalPatterns {
                            sectionCard(title: "Mental Patterns", icon: "brain.head.profile") {
                                Text(mental)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                            }
                        }

                        if let consistency = content.consistencyAnalysis {
                            sectionCard(title: "Consistency", icon: "chart.line.uptrend.xyaxis") {
                                Text(consistency)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                            }
                        }

                        if let goalProgress = content.goalProgress, !goalProgress.isEmpty {
                            sectionCard(title: "Goal Progress", icon: "target") {
                                ForEach(goalProgress.indices, id: \.self) { idx in
                                    let gp = goalProgress[idx]
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let goal = gp.goal {
                                            Text(goal)
                                                .font(Typography.headline)
                                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                        }
                                        if let analysis = gp.analysis {
                                            Text(analysis)
                                                .font(Typography.subheadline)
                                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                        }
                                        if let rec = gp.recommendation {
                                            Text(rec)
                                                .font(Typography.footnote)
                                                .foregroundColor(ColorTheme.accent)
                                        }
                                    }
                                    if idx < goalProgress.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }

                        if let tips = content.actionableTips, !tips.isEmpty {
                            sectionCard(title: "Action Items", icon: "checklist") {
                                ForEach(tips, id: \.self) { tip in
                                    bulletPoint(tip, color: ColorTheme.accent)
                                }
                            }
                        }

                        if let motivation = content.motivationalMessage {
                            CardView {
                                VStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    Text(motivation)
                                        .font(Typography.body)
                                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                                        .multilineTextAlignment(.center)
                                        .italic()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                    } else {
                        LoadingView(message: "Loading report...")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle(report.reportTypeDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private func sectionCard(title: String, icon: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.accent)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func bulletPoint(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(Typography.body)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
        }
    }
}
