import SwiftUI

enum HapticStyle {
    case light, medium, heavy
}

enum HapticNotificationType {
    case success, warning, error
}

enum HapticManager {
    static func impact(_ style: HapticStyle = .medium) {
        #if canImport(UIKit)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: uiStyle = .light
        case .medium: uiStyle = .medium
        case .heavy: uiStyle = .heavy
        }
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
        #endif
    }

    static func notification(_ type: HapticNotificationType) {
        #if canImport(UIKit)
        let uiType: UINotificationFeedbackGenerator.FeedbackType
        switch type {
        case .success: uiType = .success
        case .warning: uiType = .warning
        case .error: uiType = .error
        }
        UINotificationFeedbackGenerator().notificationOccurred(uiType)
        #endif
    }

    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
