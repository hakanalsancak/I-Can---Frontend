import SwiftUI

enum ColorTheme {
    static let accent = Color(hex: "42AAB1")

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "03213F") : .white
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "0E2F55") : Color(hex: "F6F8FA")
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F1F5F9") : Color(hex: "0F172A")
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "94A3B8") : Color(hex: "64748B")
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
