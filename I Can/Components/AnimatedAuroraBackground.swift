import SwiftUI

struct AnimatedAuroraBackground: View {
    enum Palette {
        case accent

        func colors(for scheme: ColorScheme) -> [Color] {
            switch self {
            case .accent:
                return [
                    ColorTheme.accent,
                    Color(hex: "358A90"),
                    Color(hex: "42AAB1")
                ]
            }
        }
    }

    @Environment(\.colorScheme) private var colorScheme
    let palette: Palette

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let colors = palette.colors(for: colorScheme)

            ZStack {
                ColorTheme.background(colorScheme)
                    .ignoresSafeArea()

                orb(color: colors[0].opacity(0.55), size: max(w, h) * 0.9)
                    .offset(
                        x: -w * 0.35 + sin(phase) * 40,
                        y: -h * 0.25 + cos(phase * 1.1) * 40
                    )

                orb(color: colors[1].opacity(0.45), size: max(w, h) * 0.85)
                    .offset(
                        x: w * 0.35 + cos(phase * 0.8) * 50,
                        y: h * 0.18 + sin(phase * 0.9) * 50
                    )

                orb(color: colors[2].opacity(0.35), size: max(w, h) * 0.7)
                    .offset(
                        x: sin(phase * 0.6) * 60,
                        y: h * 0.38 + cos(phase * 0.7) * 40
                    )

                LinearGradient(
                    colors: [
                        ColorTheme.background(colorScheme).opacity(0.0),
                        ColorTheme.background(colorScheme).opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }

    private func orb(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 90)
    }
}
