import SwiftUI

struct AppMaintenanceView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onRetry: () async -> Void

    @State private var isRetrying = false
    @State private var ringRotation: Double = 0
    @State private var logoPulse: CGFloat = 1.0
    @State private var appeared = false
    @State private var gearSpin: Double = 0
    @State private var dotPhase: Int = 0

    private let accent = ColorTheme.accent
    private let accentDeep = Color(hex: "358A90")

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(palette: .accent)

            VStack(spacing: 36) {
                Spacer(minLength: 20)

                statusPill

                logoHero

                VStack(spacing: 14) {
                    Text("We'll Be Right Back")
                        .font(.system(size: 34, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)

                    Text("I Can is getting a quick tune-up.\nYour streak and progress are safe — we'll see you in a moment.")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    animatedDots
                        .padding(.top, 10)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                infoCards
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                Spacer()

                retryButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) {
                ringRotation = -360
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gearSpin = 360
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                logoPulse = 1.06
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.1)) {
                appeared = true
            }
            startDotAnimation()
        }
    }

    private func startDotAnimation() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 380_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    dotPhase = (dotPhase + 1) % 4
                }
            }
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .shadow(color: accent.opacity(0.8), radius: 6)
                .scaleEffect(logoPulse)

            Text("UNDER MAINTENANCE")
                .font(.system(size: 11, weight: .heavy).width(.condensed))
                .tracking(1.6)
                .foregroundColor(ColorTheme.primaryText(colorScheme).opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(ColorTheme.cardBackground(colorScheme).opacity(0.7))
                .overlay(
                    Capsule()
                        .strokeBorder(accent.opacity(0.4), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -12)
    }

    private var logoHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 30)
                .scaleEffect(logoPulse)

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            accent.opacity(0.0),
                            accent.opacity(0.9),
                            accent.opacity(0.0),
                            accent.opacity(0.5),
                            accent.opacity(0.0)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 6])
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .strokeBorder(accent.opacity(0.18), lineWidth: 1)
                .frame(width: 230, height: 230)

            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: accent.opacity(0.35), radius: 24, y: 10)
                .scaleEffect(logoPulse)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accent, accentDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: accent.opacity(0.55), radius: 12, y: 6)

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(gearSpin))
            }
            .offset(x: 58, y: 58)
        }
        .frame(height: 260)
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
    }

    private var animatedDots: some View {
        HStack(spacing: 10) {
            dot(index: 1)
            dot(index: 2)
            dot(index: 3)
        }
    }

    private func dot(index: Int) -> some View {
        let isActive = dotPhase == index
        let fillColor: Color = isActive ? accent : accent.opacity(0.25)
        let scale: CGFloat = isActive ? 1.3 : 1.0
        return Circle()
            .fill(fillColor)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
    }

    private var infoCards: some View {
        VStack(spacing: 10) {
            infoRow(icon: "lock.shield.fill", title: "Your data is safe", subtitle: "All your progress is preserved.")
            infoRow(icon: "sparkles", title: "Upgrading behind the scenes", subtitle: "We're making I Can even better.")
            infoRow(icon: "clock.fill", title: "Back online soon", subtitle: "Tap Try Again to check.")
        }
    }

    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ColorTheme.cardBackground(colorScheme).opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 0.5)
                )
        )
    }

    private var retryButton: some View {
        Button {
            HapticManager.impact(.medium)
            Task { await retry() }
        } label: {
            HStack(spacing: 10) {
                if isRetrying {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 17, weight: .bold))
                }
                Text(isRetrying ? "Checking…" : "Try Again")
                    .font(.system(size: 17, weight: .heavy).width(.condensed))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundColor(.white)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [accent, accentDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: accent.opacity(0.5), radius: 22, y: 12)
        }
        .disabled(isRetrying)
    }

    private func retry() async {
        isRetrying = true
        await onRetry()
        isRetrying = false
    }
}
