import SwiftUI

struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: BreathPhase = .ready
    @State private var circleScale: CGFloat = 0.4
    @State private var isActive = false
    @State private var cycleCount = 0
    private let totalCycles = 5

    enum BreathPhase: String {
        case ready = "Tap to Begin"
        case inhale = "Breathe In"
        case hold = "Hold"
        case exhale = "Breathe Out"
        case complete = "Well Done"
    }

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                ZStack {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.1))
                        .frame(width: 280, height: 280)

                    Circle()
                        .fill(ColorTheme.accent.opacity(0.3))
                        .frame(width: 280 * circleScale, height: 280 * circleScale)

                    Circle()
                        .fill(ColorTheme.accent.opacity(0.6))
                        .frame(width: 200 * circleScale, height: 200 * circleScale)

                    VStack(spacing: 8) {
                        Text(phase.rawValue)
                            .font(Typography.title2)
                            .foregroundColor(.white)

                        if let mantra = AuthService.shared.currentUser?.mantra,
                           !mantra.isEmpty, isActive {
                            Text(mantra)
                                .font(Typography.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .onTapGesture {
                    if !isActive { startBreathing() }
                }

                if isActive {
                    Text("Cycle \(cycleCount)/\(totalCycles)")
                        .font(Typography.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                } else if phase == .complete {
                    PrimaryButton(title: "Done") { dismiss() }
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
    }

    private func startBreathing() {
        isActive = true
        cycleCount = 0
        runCycle()
    }

    private func runCycle() {
        guard cycleCount < totalCycles else {
            phase = .complete
            isActive = false
            HapticManager.notification(.success)
            return
        }

        cycleCount += 1

        phase = .inhale
        HapticManager.impact(.light)
        withAnimation(.easeInOut(duration: 4)) { circleScale = 1.0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            phase = .hold
            HapticManager.impact(.light)

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                phase = .exhale
                HapticManager.impact(.light)
                withAnimation(.easeInOut(duration: 4)) { circleScale = 0.4 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    runCycle()
                }
            }
        }
    }
}
