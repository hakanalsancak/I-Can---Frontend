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

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 32, height: 32)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                ZStack {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.06))
                        .frame(width: 260, height: 260)

                    Circle()
                        .fill(ColorTheme.accent.opacity(0.12))
                        .frame(width: 260 * circleScale, height: 260 * circleScale)

                    Circle()
                        .fill(ColorTheme.accent.opacity(0.25))
                        .frame(width: 180 * circleScale, height: 180 * circleScale)

                    VStack(spacing: 8) {
                        Text(phase.rawValue)
                            .font(Typography.title2)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        if let mantra = AuthService.shared.currentUser?.mantra,
                           !mantra.isEmpty, isActive {
                            Text(mantra)
                                .font(Typography.footnote)
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .onTapGesture {
                    if !isActive { startBreathing() }
                }

                Spacer()

                if isActive {
                    Text("Cycle \(cycleCount) of \(totalCycles)")
                        .font(Typography.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .padding(.bottom, 40)
                } else if phase == .complete {
                    PrimaryButton(title: "Done") { dismiss() }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                } else {
                    Text("Tap the circle to start")
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        .padding(.bottom, 40)
                }
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
