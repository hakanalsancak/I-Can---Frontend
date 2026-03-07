import SwiftUI

struct ReportDetailView: View {
    let report: AIReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let content = report.content {
                        if let summary = content.summary {
                            sectionCard(title: "Summary", icon: "doc.text") {
                                Text(summary)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(3)
                            }
                        }

                        if let strengths = content.strengths, !strengths.isEmpty {
                            sectionCard(title: "Strengths", icon: "hand.thumbsup.fill") {
                                ForEach(strengths, id: \.self) { item in
                                    bulletPoint(item, color: Color(hex: "22C55E"))
                                }
                            }
                        }

                        if let areas = content.areasForImprovement, !areas.isEmpty {
                            sectionCard(title: "Areas to Improve", icon: "arrow.up.right") {
                                ForEach(areas, id: \.self) { item in
                                    bulletPoint(item, color: Color(hex: "F97316"))
                                }
                            }
                        }

                        if let mental = content.mentalPatterns {
                            sectionCard(title: "Mental Patterns", icon: "brain") {
                                Text(mental)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(3)
                            }
                        }

                        if let consistency = content.consistencyAnalysis {
                            sectionCard(title: "Consistency", icon: "chart.line.uptrend.xyaxis") {
                                Text(consistency)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(3)
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
                                                .font(Typography.callout)
                                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                        }
                                        if let rec = gp.recommendation {
                                            Text(rec)
                                                .font(Typography.footnote)
                                                .foregroundColor(ColorTheme.accent)
                                        }
                                    }
                                    if idx < goalProgress.count - 1 {
                                        Divider().padding(.vertical, 4)
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
                            VStack(spacing: 10) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 22).width(.condensed))
                                    .foregroundColor(Color(hex: "F97316"))
                                Text(motivation)
                                    .font(Typography.callout)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                                    .italic()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(ColorTheme.subtleAccent(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    } else {
                        LoadingView(message: "Loading report...")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle(report.reportTypeDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Typography.headline)
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    private func sectionCard(title: String, icon: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(Typography.headline)
                .foregroundColor(ColorTheme.accent)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private func bulletPoint(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(Typography.body)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineSpacing(2)
        }
    }
}
