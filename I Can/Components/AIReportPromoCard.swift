import SwiftUI

struct AIReportPromoCard: View {
    let style: PromoStyle
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var shimmerOffset: CGFloat = -1

    enum PromoStyle {
        case home
        case journal
    }

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            content
        }
        .buttonStyle(.plain)
        .onAppear {
            shimmerOffset = -1
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 2
            }
        }
        .onDisappear {
            shimmerOffset = -1
        }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .home:
            homeCard
        case .journal:
            journalCard
        }
    }

    private var homeCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Performance Coach")
                        .font(Typography.headline)
                        .foregroundColor(.white)
                    Text("Get personalized coaching insights from your entries")
                        .font(Typography.footnote)
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("PREMIUM")
                        .font(.system(size: 12, weight: .heavy).width(.condensed))
                }
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white)
                .clipShape(Capsule())

                Spacer()

                HStack(spacing: 4) {
                    Text("Learn More")
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
            }
        }
        .padding(18)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GeometryReader { geo in
                    let w = geo.size.width
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w * 0.5)
                        .offset(x: shimmerOffset * w)
                        .blur(radius: 4)
                }
                .clipped()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: "7C3AED").opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private var journalCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6").opacity(0.15), Color(hex: "6D28D9").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "7C3AED"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Get AI Insights")
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Unlock premium coaching")
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Spacer()

            Text("Try")
                .font(.system(size: 13, weight: .bold).width(.condensed))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6").opacity(0.3), Color(hex: "4F46E5").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }
}
