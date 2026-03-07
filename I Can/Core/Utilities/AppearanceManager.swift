import SwiftUI

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var resolvedColorScheme: ColorScheme {
        switch self {
        case .system:
            #if canImport(UIKit)
            let style = UIScreen.main.traitCollection.userInterfaceStyle
            return style == .dark ? .dark : .light
            #else
            return .dark
            #endif
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@Observable
final class AppearanceManager {
    static let shared = AppearanceManager()

    var current: AppAppearance {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "app_appearance")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_appearance") ?? "Dark"
        self.current = AppAppearance(rawValue: saved) ?? .dark
    }
}
