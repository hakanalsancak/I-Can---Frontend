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
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: currentPrompt.icon)
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.accent)
                        .padding(.top, 32)

                    Text(currentPrompt.title)
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text(currentPrompt.instruction)
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(currentPrompt.duration)
                    }
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    Spacer(minLength: 40)

                    HStack(spacing: 16) {
                        Button {
                            withAnimation {
                                currentPromptIndex = (currentPromptIndex - 1 + prompts.count) % prompts.count
                            }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundColor(ColorTheme.accent)
                        }

                        Text("\(currentPromptIndex + 1) / \(prompts.count)")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 60)

                        Button {
                            withAnimation {
                                currentPromptIndex = (currentPromptIndex + 1) % prompts.count
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundColor(ColorTheme.accent)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Visualization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
