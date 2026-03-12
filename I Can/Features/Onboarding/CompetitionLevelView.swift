import SwiftUI

struct CompetitionLevelView: View {
    @Binding var level: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let levels: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("beginner", "Beginner", "Just starting out", "figure.walk"),
        ("amateur", "Amateur", "Playing recreationally", "figure.run"),
        ("semi_pro", "Semi-Pro", "Competing at a high level", "figure.strengthtraining.traditional"),
        ("professional", "Professional", "Full-time athlete", "trophy"),
        ("elite", "Elite / International", "National or international level", "star"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Competition Level")
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("What level do you compete at?")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 32)
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                ForEach(levels, id: \.id) { item in
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level = item.id
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(level == item.id ? ColorTheme.accent : ColorTheme.secondaryText(colorScheme))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 17, weight: .semibold).width(.condensed))
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                Text(item.subtitle)
                                    .font(.system(size: 13, weight: .medium).width(.condensed))
                                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            }

                            Spacer()

                            if level == item.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            level == item.id
                            ? ColorTheme.accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
                            : ColorTheme.cardBackground(colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    level == item.id ? ColorTheme.accent : ColorTheme.separator(colorScheme),
                                    lineWidth: level == item.id ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 0) {
                Divider().opacity(0.3)
                HStack(spacing: 12) {
                    Button {
                        withAnimation { onBack() }
                    } label: {
                        Text("Back")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }

                    PrimaryButton(
                        title: "Continue",
                        isDisabled: level.isEmpty
                    ) {
                        withAnimation { onNext() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
    }
}
