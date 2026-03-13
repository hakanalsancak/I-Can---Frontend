import SwiftUI

enum ColorTheme {
    static let accent = Color(hex: "42AAB1")

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "42AAB1"), Color(hex: "358A90")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: "F97316"), Color(hex: "EF4444")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "0A1628") : Color(hex: "EEF0F4")
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "152035") : Color(hex: "FFFFFF")
    }

    static func elevatedBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1A2842") : Color(hex: "E8EAF0")
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F1F5F9") : Color(hex: "1A1D26")
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "94A3B8") : Color(hex: "4A5568")
    }

    static func tertiaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "475569") : Color(hex: "9CA3AF")
    }

    static func separator(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color(hex: "D1D5DB")
    }

    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .clear : Color(hex: "0F172A").opacity(0.1)
    }

    static func subtleAccent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.15) : accent.opacity(0.12)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
