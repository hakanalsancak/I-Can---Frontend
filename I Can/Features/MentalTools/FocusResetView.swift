import SwiftUI

struct FocusResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: ResetPhase = .ready
    @State private var countdown = 10
    @State private var ringProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1

    private let steps = [
        "Close your eyes",
        "Release all tension",
        "Clear your mind",
        "Take a deep breath",
        "Feel the ground beneath you",
        "Let go of the last play",
        "Reset your focus",
        "Lock in on what's next",
        "You are ready",
        "Go."
    ]

    enum ResetPhase {
        case ready, active, complete
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
                        .stroke(Color(hex: "F97316").opacity(0.15), lineWidth: 6)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "F97316"), Color(hex: "EF4444")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .fill(Color(hex: "F97316").opacity(0.06))
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulseScale)

                    VStack(spacing: 8) {
                        switch phase {
                        case .ready:
                            Text("FOCUS RESET")
                                .font(.system(size: 12, weight: .heavy).width(.condensed))
                                .foregroundColor(Color(hex: "F97316"))
                                .tracking(2)
                            Text("10s")
                                .font(Typography.number(48))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        case .active:
                            Text("\(countdown)")
                                .font(Typography.number(56))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                .contentTransition(.numericText())
                        case .complete:
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(hex: "22C55E"))
                        }
                    }
                }

                Spacer()
                    .frame(height: 32)

                Text(currentMessage)
                    .font(.system(size: 22, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .frame(height: 60)
                    .padding(.horizontal, 40)
                    .id(currentMessage)
                    .transition(.opacity)

                Spacer()

                if phase == .ready {
                    Button {
                        startReset()
                    } label: {
                        Text("Start Reset")
                            .font(.system(size: 16, weight: .bold).width(.condensed))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F97316"), Color(hex: "EF4444")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(hex: "F97316").opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                } else if phase == .complete {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold).width(.condensed))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "22C55E").gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
                    .frame(height: 50)
            }
        }
    }

    private var currentMessage: String {
        switch phase {
        case .ready:
            return "Quick mental reset\nbetween plays"
        case .active:
            let idx = min(10 - countdown, steps.count - 1)
            return steps[idx]
        case .complete:
            return "You're locked in."
        }
    }

    private func startReset() {
        phase = .active
        countdown = 10
        ringProgress = 0
        HapticManager.impact(.medium)
        tick()
    }

    private func tick() {
        guard countdown > 0 else {
            withAnimation(.easeInOut(duration: 0.4)) {
                phase = .complete
                ringProgress = 1
            }
            HapticManager.notification(.success)
            return
        }

        withAnimation(.easeInOut(duration: 0.8)) {
            ringProgress = CGFloat(10 - countdown) / 10.0
            pulseScale = 1.06
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.4)) {
                pulseScale = 1.0
            }
        }

        HapticManager.impact(.light)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                countdown -= 1
            }
            tick()
        }
    }
}
