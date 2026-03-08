import SwiftUI

enum Typography {
    static let largeTitle = Font.system(size: 38, weight: .heavy).width(.condensed)
    static let title = Font.system(size: 32, weight: .bold).width(.condensed)
    static let title2 = Font.system(size: 26, weight: .bold).width(.condensed)
    static let title3 = Font.system(size: 22, weight: .bold).width(.condensed)
    static let headline = Font.system(size: 18, weight: .semibold).width(.condensed)
    static let body = Font.system(size: 17, weight: .regular).width(.condensed)
    static let callout = Font.system(size: 16, weight: .regular).width(.condensed)
    static let subheadline = Font.system(size: 15, weight: .medium).width(.condensed)
    static let footnote = Font.system(size: 14, weight: .regular).width(.condensed)
    static let caption = Font.system(size: 13, weight: .medium).width(.condensed)

    static func number(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded).width(.condensed)
    }
}
