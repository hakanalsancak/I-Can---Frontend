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
    @State private var showModeContent = false
    @State private var ambientRotation: Double = 0
    @State private var showCompletion = false

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
            // Dynamic background
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                if let mode = selectedMode {
                    RadialGradient(
                        colors: [
                            mode.gradient[0].opacity(isActive ? 0.1 : 0.04),
                            mode.gradient[1].opacity(0.02),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 380
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.5), value: isActive)
                }
            }

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

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.1))
                        .frame(width: 76, height: 76)

                    Circle()
                        .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
                        .frame(width: 76, height: 76)

                    Image(systemName: "wind")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorTheme.accent, ColorTheme.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .opacity(showModeContent ? 1 : 0)
                .scaleEffect(showModeContent ? 1 : 0.6)

                Text("Breathing Exercise")
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .opacity(showModeContent ? 1 : 0)
                    .offset(y: showModeContent ? 0 : 12)

                Text("Choose your session")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .opacity(showModeContent ? 1 : 0)
                    .offset(y: showModeContent ? 0 : 12)
            }
            .padding(.bottom, 36)

            VStack(spacing: 12) {
                ForEach(Array(BreathingMode.allCases.enumerated()), id: \.element.rawValue) { index, mode in
                    modeCard(mode)
                        .opacity(showModeContent ? 1 : 0)
                        .offset(y: showModeContent ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.08),
                            value: showModeContent
                        )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showModeContent = true
            }
        }
    }

    private func modeCard(_ mode: BreathingMode) -> some View {
        Button {
            HapticManager.impact(.medium)
            selectedMode = mode
        } label: {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(LinearGradient(colors: mode.gradient, startPoint: .top, endPoint: .bottom))
                    .frame(width: 4)
                    .padding(.vertical, 14)

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: mode.gradient.map { $0.opacity(0.12) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: mode.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        Text(mode.subtitle)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Text(mode.pattern)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(mode.gradient[0])

                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(mode.totalDuration)s")
                                .font(.system(size: 11, weight: .semibold).width(.condensed))
                        }
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
            }
            .padding(.vertical, 10)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
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
                        showModeContent = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showModeContent = true
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
                Spacer()
                closeButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            if phase == .complete {
                completionView(mode)
            } else {
                Spacer()
                breathingCircle(mode)
                Spacer()
                bottomInfo(mode)
            }
        }
    }

    // MARK: - Breathing Circle

    private func breathingCircle(_ mode: BreathingMode) -> some View {
        let gradient = LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        let primaryColor = mode.gradient[0]

        return ZStack {
            // Decorative dashed ring (slowly rotates)
            Circle()
                .stroke(primaryColor.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(ambientRotation))

            // Outer boundary ring
            Circle()
                .stroke(primaryColor.opacity(0.08), lineWidth: 1.5)
                .frame(width: 270, height: 270)

            // Outer fill
            Circle()
                .fill(primaryColor.opacity(0.03))
                .frame(width: 270, height: 270)
                .scaleEffect(outerPulse)

            // Glow layer behind main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [primaryColor.opacity(0.15 * Double(circleScale)), .clear],
                        center: .center,
                        startRadius: 40 * circleScale,
                        endRadius: 140 * circleScale
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 20)

            // Intermediate ring
            Circle()
                .fill(primaryColor.opacity(0.08))
                .frame(width: 220 * circleScale, height: 220 * circleScale)

            // Inner breathing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [primaryColor.opacity(0.25), primaryColor.opacity(0.1)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90 * circleScale
                    )
                )
                .frame(width: 170 * circleScale, height: 170 * circleScale)

            // Core bright circle
            Circle()
                .fill(primaryColor.opacity(0.15))
                .frame(width: 100 * circleScale, height: 100 * circleScale)

            // Progress ring
            if isActive || phase == .complete {
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 270, height: 270)
                    .rotationEffect(.degrees(-90))

                // Glow dot at progress ring tip
                Circle()
                    .fill(primaryColor)
                    .frame(width: 6, height: 6)
                    .blur(radius: 3)
                    .offset(y: -135)
                    .rotationEffect(.degrees(Double(ringProgress) * 360 - 90))
                    .opacity(ringProgress > 0 ? 1 : 0)
            }

            // Center content
            VStack(spacing: 6) {
                if isActive {
                    Text("\(secondsLeft)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(primaryColor)
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
        .onAppear {
            ambientRotation = 0
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                ambientRotation = 360
            }
        }
        .onTapGesture {
            if !isActive && phase != .complete {
                startBreathing(mode)
            }
        }
    }

    // MARK: - Completion View

    private func completionView(_ mode: BreathingMode) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .strokeBorder(mode.gradient[0].opacity(0.08), lineWidth: 1)
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(mode.gradient[0].opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .scaleEffect(showCompletion ? 1 : 0.5)
                .opacity(showCompletion ? 1 : 0)

                VStack(spacing: 6) {
                    Text("Well Done")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Session complete")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .opacity(showCompletion ? 1 : 0)
                .offset(y: showCompletion ? 0 : 10)

                // Stats row
                HStack(spacing: 0) {
                    statItem(value: "\(mode.cycles)", label: "Cycles", color: mode.gradient[0])

                    dividerLine

                    statItem(value: mode.pattern, label: "Pattern", color: mode.gradient[0])

                    dividerLine

                    statItem(value: "\(mode.totalDuration)s", label: "Duration", color: mode.gradient[0])
                }
                .padding(.vertical, 16)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 24)
                .opacity(showCompletion ? 1 : 0)
                .offset(y: showCompletion ? 0 : 15)
            }

            Spacer()
            Spacer()

            PrimaryButton(title: "Done") { dismiss() }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(showCompletion ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15)) {
                showCompletion = true
            }
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(ColorTheme.separator(colorScheme))
            .frame(width: 1, height: 28)
    }

    // MARK: - Bottom Info

    private func bottomInfo(_ mode: BreathingMode) -> some View {
        VStack(spacing: 14) {
            if isActive {
                HStack(spacing: 8) {
                    phasePill("In", seconds: Int(mode.inhale), active: phase == .inhale, mode: mode)
                    phasePill("Hold", seconds: Int(mode.hold), active: phase == .hold, mode: mode)
                    phasePill("Out", seconds: Int(mode.exhale), active: phase == .exhale, mode: mode)
                }
                .padding(.horizontal, 24)

                // Cycle progress dots
                HStack(spacing: 8) {
                    ForEach(1...mode.cycles, id: \.self) { cycle in
                        Circle()
                            .fill(cycle <= cycleCount ? mode.gradient[0] : mode.gradient[0].opacity(0.15))
                            .frame(width: 7, height: 7)
                            .animation(.easeInOut(duration: 0.3), value: cycleCount)
                    }
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

    private func phasePill(_ label: String, seconds: Int, active: Bool, mode: BreathingMode) -> some View {
        VStack(spacing: 3) {
            Text("\(seconds)s")
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10, weight: .semibold).width(.condensed))
                .textCase(.uppercase)
        }
        .foregroundColor(active ? .white : ColorTheme.tertiaryText(colorScheme))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            active
                ? AnyShapeStyle(LinearGradient(colors: mode.gradient, startPoint: .leading, endPoint: .trailing))
                : AnyShapeStyle(ColorTheme.elevatedBackground(colorScheme))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .frame(width: 36, height: 36)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(Circle())
        }
    }

    // MARK: - Breathing Logic

    private func startBreathing(_ mode: BreathingMode) {
        isActive = true
        cycleCount = 0
        ringProgress = 0
        showCompletion = false
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
