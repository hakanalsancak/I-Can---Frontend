import SwiftUI

struct ReportDetailView: View {
    let report: AIReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    reportHeader

                    if let content = report.content {
                        if let summary = content.summary {
                            sectionCard(title: "Overview", icon: "doc.text.fill", accentColor: Color(hex: "3B82F6")) {
                                Text(summary)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(4)
                            }
                        }

                        if let strengths = content.strengths, !strengths.isEmpty {
                            sectionCard(title: "Your Strengths", icon: "arrow.up.circle.fill", accentColor: Color(hex: "22C55E")) {
                                ForEach(Array(strengths.enumerated()), id: \.offset) { idx, item in
                                    bulletPoint(item, color: Color(hex: "22C55E"), index: idx + 1)
                                    if idx < strengths.count - 1 {
                                        Divider()
                                            .padding(.vertical, 4)
                                            .padding(.leading, 30)
                                    }
                                }
                            }
                        }

                        if let areas = content.areasForImprovement, !areas.isEmpty {
                            sectionCard(title: "Areas to Improve", icon: "target", accentColor: Color(hex: "F97316")) {
                                ForEach(Array(areas.enumerated()), id: \.offset) { idx, item in
                                    bulletPoint(item, color: Color(hex: "F97316"), index: idx + 1)
                                    if idx < areas.count - 1 {
                                        Divider()
                                            .padding(.vertical, 4)
                                            .padding(.leading, 30)
                                    }
                                }
                            }
                        }

                        if let mental = content.mentalPatterns {
                            sectionCard(title: "Mental Patterns", icon: "brain.fill", accentColor: Color(hex: "8B5CF6")) {
                                Text(mental)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(4)
                            }
                        }

                        if let physical = content.physicalPatterns {
                            sectionCard(title: "Physical Patterns", icon: "figure.run", accentColor: Color(hex: "06B6D4")) {
                                Text(physical)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(4)
                            }
                        }

                        if let consistency = content.consistencyAnalysis {
                            sectionCard(title: "Consistency", icon: "chart.line.uptrend.xyaxis", accentColor: ColorTheme.accent) {
                                Text(consistency)
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                    .lineSpacing(4)
                            }
                        }

                        if let growthAreas = content.resolvedGrowthAreas, !growthAreas.isEmpty {
                            sectionCard(title: "Growth Areas", icon: "arrow.up.right", accentColor: Color(hex: "EAB308")) {
                                ForEach(growthAreas.indices, id: \.self) { idx in
                                    let gp = growthAreas[idx]
                                    VStack(alignment: .leading, spacing: 6) {
                                        if let title = gp.title {
                                            HStack(spacing: 8) {
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(Color(hex: "EAB308"))
                                                Text(title)
                                                    .font(.system(size: 15, weight: .bold).width(.condensed))
                                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                            }
                                        }
                                        if let analysis = gp.analysis {
                                            Text(analysis)
                                                .font(Typography.body)
                                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                                .lineSpacing(3)
                                                .padding(.leading, 20)
                                        }
                                        if let rec = gp.recommendation {
                                            HStack(alignment: .top, spacing: 6) {
                                                Image(systemName: "lightbulb.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(hex: "EAB308"))
                                                    .padding(.top, 2)
                                                Text(rec)
                                                    .font(.system(size: 13, weight: .medium).width(.condensed))
                                                    .foregroundColor(Color(hex: "EAB308"))
                                                    .lineSpacing(2)
                                            }
                                            .padding(10)
                                            .background(Color(hex: "EAB308").opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .padding(.leading, 20)
                                        }
                                    }
                                    if idx < growthAreas.count - 1 {
                                        Divider().padding(.vertical, 8)
                                    }
                                }
                            }
                        }

                        if let tips = content.actionableTips, !tips.isEmpty {
                            sectionCard(title: "Action Plan", icon: "checklist", accentColor: Color(hex: "2563EB")) {
                                ForEach(Array(tips.enumerated()), id: \.offset) { idx, tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(idx + 1)")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 22, height: 22)
                                            .background(Color(hex: "2563EB"))
                                            .clipShape(Circle())
                                            .padding(.top, 1)
                                        Text(tip)
                                            .font(Typography.body)
                                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                                            .lineSpacing(3)
                                    }
                                    if idx < tips.count - 1 {
                                        Divider()
                                            .padding(.vertical, 4)
                                            .padding(.leading, 32)
                                    }
                                }
                            }
                        }

                        if let motivation = content.motivationalMessage {
                            motivationCard(motivation)
                        }
                    } else {
                        LoadingView(message: "Loading report...")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(report.dateRangeDisplay)
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }

    // MARK: - Report Header

    private var reportHeader: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: report.reportIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(report.reportTypeDisplay)
                    .font(.system(size: 13, weight: .bold).width(.condensed))
                    .foregroundColor(Color(hex: "7C3AED"))
                    .textCase(.uppercase)
            }

            if let created = report.createdDateDisplay {
                Text("Generated \(created)")
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Section Card

    private func sectionCard(title: String, icon: String, accentColor: Color, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .textCase(.uppercase)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    // MARK: - Bullet Point

    private func bulletPoint(_ text: String, color: Color, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(color)
                .clipShape(Circle())
                .padding(.top, 2)
            Text(text)
                .font(Typography.body)
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineSpacing(3)
        }
    }

    // MARK: - Motivation Card

    private func motivationCard(_ text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "F97316"), Color(hex: "EF4444")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(text)
                .font(.system(size: 15, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .italic()
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            ZStack {
                ColorTheme.cardBackground(colorScheme)
                LinearGradient(
                    colors: [Color(hex: "F97316").opacity(0.06), Color(hex: "EF4444").opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: "F97316").opacity(0.2), Color(hex: "EF4444").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
