import SwiftUI

struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMode: BreathingMode?
    @State private var phase: BreathPhase = .ready
    @State private var circleScale: CGFloat = 0.35
    @State private var isActive = false
    @State private var cycleCount = 0
    @State private var secondsLeft = 0
    @State private var timer: Timer?
    @State private var ringProgress: CGFloat = 0
    @State private var outerPulse: CGFloat = 1.0

    enum BreathingMode: String, CaseIterable {
        case game = "Before Game"
        case training = "Before Training"
        case sleep = "Before Sleep"

        var icon: String {
            switch self {
            case .game: return "sportscourt.fill"
            case .training: return "figure.run"
            case .sleep: return "moon.fill"
            }
        }

        var gradient: [Color] {
            switch self {
            case .game: return [Color(hex: "EF4444"), Color(hex: "F97316")]
            case .training: return [Color(hex: "3B82F6"), Color(hex: "06B6D4")]
            case .sleep: return [Color(hex: "7C3AED"), Color(hex: "6366F1")]
            }
        }

        var subtitle: String {
            switch self {
            case .game: return "Energize & focus your mind"
            case .training: return "Calm your body & sharpen focus"
            case .sleep: return "Deep relaxation for recovery"
            }
        }

        var inhale: Double {
            switch self {
            case .game: return 4
            case .training: return 4
            case .sleep: return 4
            }
        }

        var hold: Double {
            switch self {
            case .game: return 4
            case .training: return 7
            case .sleep: return 7
            }
        }

        var exhale: Double {
            switch self {
            case .game: return 4
            case .training: return 8
            case .sleep: return 8
            }
        }

        var cycles: Int {
            switch self {
            case .game: return 4
            case .training: return 5
            case .sleep: return 6
            }
        }

        var pattern: String {
            "\(Int(inhale))-\(Int(hold))-\(Int(exhale))"
        }

        var totalDuration: Int {
            Int(inhale + hold + exhale) * cycles
        }
    }

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

            if let mode = selectedMode {
                exerciseView(mode)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                modeSelectionView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: selectedMode != nil)
    }

    // MARK: - Mode Selection

    private var modeSelectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                closeButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "wind")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.accent, ColorTheme.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, 4)

                Text("Breathing Exercise")
                    .font(.system(size: 26, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Choose your session")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.bottom, 36)

            VStack(spacing: 12) {
                ForEach(BreathingMode.allCases, id: \.rawValue) { mode in
                    modeCard(mode)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func modeCard(_ mode: BreathingMode) -> some View {
        Button {
            HapticManager.impact(.medium)
            selectedMode = mode
        } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.rawValue)
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text(mode.subtitle)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(mode.pattern)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(mode.gradient[0])

                    Text("\(mode.totalDuration)s")
                        .font(.system(size: 11, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise View

    private func exerciseView(_ mode: BreathingMode) -> some View {
        VStack(spacing: 0) {
            HStack {
                if !isActive && phase != .complete {
                    Button {
                        HapticManager.selection()
                        stopTimer()
                        selectedMode = nil
                        phase = .ready
                        circleScale = 0.35
                        cycleCount = 0
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 32, height: 32)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
                Spacer()
                closeButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            breathingCircle(mode)

            Spacer()

            bottomInfo(mode)
        }
    }

    private func breathingCircle(_ mode: BreathingMode) -> some View {
        let gradient = LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)

        return ZStack {
            Circle()
                .stroke(mode.gradient[0].opacity(0.08), lineWidth: 2)
                .frame(width: 280, height: 280)

            Circle()
                .fill(mode.gradient[0].opacity(0.04))
                .frame(width: 280, height: 280)
                .scaleEffect(outerPulse)

            Circle()
                .fill(mode.gradient[0].opacity(0.1))
                .frame(width: 240 * circleScale, height: 240 * circleScale)

            Circle()
                .fill(mode.gradient[0].opacity(0.2))
                .frame(width: 180 * circleScale, height: 180 * circleScale)

            if isActive || phase == .complete {
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 6) {
                if isActive {
                    Text("\(secondsLeft)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(mode.gradient[0])
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: secondsLeft)
                }

                Text(phase.rawValue)
                    .font(.system(size: 18, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                if let mantra = AuthService.shared.currentUser?.mantra,
                   !mantra.isEmpty, isActive, phase == .hold {
                    Text(mantra)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: phase)
        }
        .onTapGesture {
            if !isActive && phase != .complete {
                startBreathing(mode)
            }
        }
    }

    private func bottomInfo(_ mode: BreathingMode) -> some View {
        VStack(spacing: 12) {
            if isActive {
                HStack(spacing: 20) {
                    phaseLabel("In", seconds: Int(mode.inhale), active: phase == .inhale, color: mode.gradient[0])
                    phaseLabel("Hold", seconds: Int(mode.hold), active: phase == .hold, color: mode.gradient[0])
                    phaseLabel("Out", seconds: Int(mode.exhale), active: phase == .exhale, color: mode.gradient[0])
                }
                .padding(.horizontal, 24)

                Text("Cycle \(cycleCount) of \(mode.cycles)")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            } else if phase == .complete {
                VStack(spacing: 14) {
                    Text("Session Complete")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    PrimaryButton(title: "Done") { dismiss() }
                        .padding(.horizontal, 24)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(mode.gradient[0].opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text("Tap the circle to start")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
            }
        }
        .padding(.bottom, 48)
    }

    private func phaseLabel(_ label: String, seconds: Int, active: Bool, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(seconds)s")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(active ? color : ColorTheme.tertiaryText(colorScheme))

            Text(label)
                .font(.system(size: 11, weight: .semibold).width(.condensed))
                .foregroundColor(active ? color : ColorTheme.tertiaryText(colorScheme))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(active ? color.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: active)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            stopTimer()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(width: 32, height: 32)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(Circle())
        }
    }

    // MARK: - Breathing Logic

    private func startBreathing(_ mode: BreathingMode) {
        isActive = true
        cycleCount = 0
        ringProgress = 0
        runCycle(mode)
    }

    private func runCycle(_ mode: BreathingMode) {
        guard cycleCount < mode.cycles else {
            phase = .complete
            isActive = false
            withAnimation(.easeInOut(duration: 0.5)) {
                ringProgress = 1.0
                circleScale = 0.5
            }
            HapticManager.notification(.success)
            return
        }

        cycleCount += 1
        let totalPhaseSeconds = mode.inhale + mode.hold + mode.exhale
        let cycleFraction = 1.0 / Double(mode.cycles)

        // Inhale
        phase = .inhale
        secondsLeft = Int(mode.inhale)
        HapticManager.impact(.light)
        withAnimation(.easeInOut(duration: mode.inhale)) {
            circleScale = 1.0
            outerPulse = 1.08
        }
        startCountdown(Int(mode.inhale))

        let baseProgress = Double(cycleCount - 1) * cycleFraction

        withAnimation(.linear(duration: mode.inhale)) {
            ringProgress = baseProgress + cycleFraction * (mode.inhale / totalPhaseSeconds)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mode.inhale) { [self] in
            guard isActive else { return }

            // Hold
            phase = .hold
            secondsLeft = Int(mode.hold)
            HapticManager.impact(.light)
            withAnimation(.easeInOut(duration: 0.5)) { outerPulse = 1.0 }
            startCountdown(Int(mode.hold))

            withAnimation(.linear(duration: mode.hold)) {
                ringProgress = baseProgress + cycleFraction * ((mode.inhale + mode.hold) / totalPhaseSeconds)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + mode.hold) { [self] in
                guard isActive else { return }

                // Exhale
                phase = .exhale
                secondsLeft = Int(mode.exhale)
                HapticManager.impact(.light)
                withAnimation(.easeInOut(duration: mode.exhale)) {
                    circleScale = 0.35
                    outerPulse = 0.95
                }
                startCountdown(Int(mode.exhale))

                withAnimation(.linear(duration: mode.exhale)) {
                    ringProgress = baseProgress + cycleFraction
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + mode.exhale) { [self] in
                    guard isActive else { return }
                    withAnimation(.easeInOut(duration: 0.3)) { outerPulse = 1.0 }
                    runCycle(mode)
                }
            }
        }
    }

    private func startCountdown(_ from: Int) {
        stopTimer()
        secondsLeft = from
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if secondsLeft > 1 {
                secondsLeft -= 1
            } else {
                t.invalidate()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
