import SwiftUI

struct ForceUpdateView: View {
    @Environment(\.colorScheme) private var colorScheme

    var currentVersion: String? = nil
    var minVersion: String? = nil

    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6760717419")!

    @State private var ringRotation: Double = 0
    @State private var logoPulse: CGFloat = 1.0
    @State private var appeared = false
    @State private var badgeBob: CGFloat = 0
    @State private var orbShift: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(palette: .accent)

            VStack(spacing: 28) {
                statusPill

                logoHero

                VStack(spacing: 14) {
                    Text("Update Required")
                        .font(.system(size: 34, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .multilineTextAlignment(.center)

                    Text("A fresher, faster I Can is ready.\nGrab the latest version to keep your streak alive.")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    if let from = currentVersion, let to = minVersion {
                        versionChip(from: from, to: to)
                            .padding(.top, 6)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                whatsNewList
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                Spacer(minLength: 24)

                updateButton
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                logoPulse = 1.06
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                badgeBob = -6
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                orbShift = 1
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ColorTheme.accent)
                .frame(width: 8, height: 8)
                .shadow(color: ColorTheme.accent.opacity(0.8), radius: 6)
                .scaleEffect(logoPulse)

            Text("NEW VERSION AVAILABLE")
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
                        .strokeBorder(ColorTheme.accent.opacity(0.35), lineWidth: 1)
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
                        colors: [ColorTheme.accent.opacity(0.55), .clear],
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
                            ColorTheme.accent.opacity(0.0),
                            ColorTheme.accent.opacity(0.9),
                            ColorTheme.accent.opacity(0.0),
                            ColorTheme.accent.opacity(0.6),
                            ColorTheme.accent.opacity(0.0)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
                .frame(width: 230, height: 230)

            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: ColorTheme.accent.opacity(0.45), radius: 24, y: 10)
                .scaleEffect(logoPulse)

            ZStack {
                Circle()
                    .fill(ColorTheme.accentGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: ColorTheme.accent.opacity(0.6), radius: 12, y: 6)

                Image(systemName: "arrow.down")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
            .offset(x: 58, y: 58 + badgeBob)
        }
        .frame(height: 230)
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
    }

    private func versionChip(from: String, to: String) -> some View {
        HStack(spacing: 10) {
            Text("v\(from)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ColorTheme.accent)

            Text("v\(to)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(ColorTheme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(ColorTheme.subtleAccent(colorScheme))
        )
    }

    private var whatsNewList: some View {
        VStack(spacing: 10) {
            featureRow(icon: "sparkles", text: "New features & improvements")
            featureRow(icon: "bolt.fill", text: "Faster, smoother performance")
            featureRow(icon: "shield.fill", text: "Important stability fixes")
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorTheme.subtleAccent(colorScheme))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ColorTheme.accent)
            }

            Text(text)
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.primaryText(colorScheme).opacity(0.85))

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

    private var updateButton: some View {
        Button {
            HapticManager.impact(.medium)
            UIApplication.shared.open(appStoreURL)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Update Now")
                    .font(.system(size: 17, weight: .heavy).width(.condensed))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundColor(.white)
            .background(
                ZStack {
                    ColorTheme.accentGradient
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: ColorTheme.accent.opacity(0.55), radius: 22, y: 12)
        }
    }
}
