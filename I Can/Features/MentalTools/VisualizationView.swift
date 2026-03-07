import SwiftUI

struct VisualizationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPromptIndex = 0

    private let prompts = [
        VisualizationPrompt(
            title: "Pre-Game Focus",
            instruction: "Close your eyes. Imagine yourself walking onto the field. Feel the energy. See yourself performing at your absolute best.",
            duration: "3 minutes",
            icon: "figure.walk"
        ),
        VisualizationPrompt(
            title: "Clutch Moment",
            instruction: "Picture the most pressure-filled moment in your sport. See yourself staying calm, making the right decision, and executing perfectly.",
            duration: "2 minutes",
            icon: "bolt.fill"
        ),
        VisualizationPrompt(
            title: "Recovery & Growth",
            instruction: "Visualize your body recovering stronger after each training session. See your skills improving day by day. Feel the progress.",
            duration: "3 minutes",
            icon: "arrow.up.heart"
        ),
        VisualizationPrompt(
            title: "Perfect Execution",
            instruction: "Choose one specific skill. Visualize performing it with perfect technique — over and over. Feel every movement in detail.",
            duration: "2 minutes",
            icon: "target"
        ),
        VisualizationPrompt(
            title: "Winning Mentality",
            instruction: "See yourself achieving your biggest goal. How does it feel? Who is with you? Hold that feeling and carry it into your next session.",
            duration: "3 minutes",
            icon: "trophy"
        ),
    ]

    var currentPrompt: VisualizationPrompt {
        prompts[currentPromptIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(ColorTheme.subtleAccent(colorScheme))
                                .frame(width: 96, height: 96)
                            Image(systemName: currentPrompt.icon)
                                .font(.system(size: 36, weight: .medium).width(.condensed))
                                .foregroundStyle(ColorTheme.accentGradient)
                        }
                        .padding(.top, 40)

                        Text(currentPrompt.title)
                            .font(Typography.title)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        Text(currentPrompt.instruction)
                            .font(Typography.body)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12).width(.condensed))
                            Text(currentPrompt.duration)
                        }
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }

                HStack(spacing: 20) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPromptIndex = (currentPromptIndex - 1 + prompts.count) % prompts.count
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                            .frame(width: 40, height: 40)
                            .background(ColorTheme.subtleAccent(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    HStack(spacing: 6) {
                        ForEach(0..<prompts.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentPromptIndex ? ColorTheme.accent : ColorTheme.separator(colorScheme))
                                .frame(width: 6, height: 6)
                        }
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPromptIndex = (currentPromptIndex + 1) % prompts.count
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                            .frame(width: 40, height: 40)
                            .background(ColorTheme.subtleAccent(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.bottom, 40)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Visualization")
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
}

struct VisualizationPrompt {
    let title: String
    let instruction: String
    let duration: String
    let icon: String
}
