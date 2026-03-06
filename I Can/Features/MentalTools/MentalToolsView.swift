import SwiftUI

struct MentalToolsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBreathing = false
    @State private var showVisualization = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    mantraCard

                    Button { showBreathing = true } label: {
                        toolCard(
                            title: "Breathing Exercise",
                            subtitle: "Calm your mind before competition",
                            icon: "wind",
                            color: .blue
                        )
                    }

                    Button { showVisualization = true } label: {
                        toolCard(
                            title: "Visualization",
                            subtitle: "Mentally rehearse success",
                            icon: "eye",
                            color: .purple
                        )
                    }

                    toolCard(
                        title: "Focus Reset",
                        subtitle: "Quick mental reset between plays",
                        icon: "arrow.counterclockwise",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Mental Tools")
            .fullScreenCover(isPresented: $showBreathing) {
                BreathingExerciseView()
            }
            .sheet(isPresented: $showVisualization) {
                VisualizationView()
            }
        }
    }

    private var mantraCard: some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundColor(ColorTheme.accent)

                if let mantra = AuthService.shared.currentUser?.mantra, !mantra.isEmpty {
                    Text(mantra)
                        .font(Typography.title3)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Set your personal mantra in settings")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Text("Your Personal Mantra")
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func toolCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        CardView {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
    }
}
