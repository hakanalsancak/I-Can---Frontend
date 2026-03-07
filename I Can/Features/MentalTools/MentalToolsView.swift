import SwiftUI

struct MentalToolsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBreathing = false
    @State private var showVisualization = false
    @State private var showFocusReset = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("Mind")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        mantraCard

                        Text("EXERCISES")
                            .sectionHeader(colorScheme)
                            .padding(.top, 4)

                        Button { showBreathing = true } label: {
                            toolCard(
                                title: "Breathing Exercise",
                                subtitle: "Calm your mind before competition",
                                icon: "wind",
                                color: Color(hex: "3B82F6")
                            )
                        }
                        .buttonStyle(.plain)

                        Button { showVisualization = true } label: {
                            toolCard(
                                title: "Visualization",
                                subtitle: "Mentally rehearse success",
                                icon: "eye",
                                color: Color(hex: "8B5CF6")
                            )
                        }
                        .buttonStyle(.plain)

                        Button { showFocusReset = true } label: {
                            toolCard(
                                title: "Focus Reset",
                                subtitle: "Quick mental reset between plays",
                                icon: "arrow.counterclockwise",
                                color: Color(hex: "F97316")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingExerciseView()
            }
            .sheet(isPresented: $showVisualization) {
                VisualizationView()
            }
            .fullScreenCover(isPresented: $showFocusReset) {
                FocusResetView()
            }
        }
    }

    private var mantraCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.system(size: 20).width(.condensed))
                .foregroundColor(ColorTheme.accent)

            if let mantra = AuthService.shared.currentUser?.mantra, !mantra.isEmpty {
                Text(mantra)
                    .font(Typography.title3)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
            } else {
                Text("Set your personal mantra in settings")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Text("Your Personal Mantra")
                .font(Typography.caption)
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(ColorTheme.subtleAccent(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ColorTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private func toolCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium).width(.condensed))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
