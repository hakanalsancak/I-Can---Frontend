import SwiftUI

struct CalendarDayView: View {
    let date: Date
    let hasEntry: Bool
    let isSelected: Bool
    let isToday: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(Typography.callout)
                .foregroundColor(textColor)

            Circle()
                .fill(hasEntry ? ColorTheme.accent : .clear)
                .frame(width: 6, height: 6)
        }
        .frame(width: 36, height: 40)
        .background(isSelected ? ColorTheme.accent : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return ColorTheme.accent }
        return ColorTheme.primaryText(colorScheme)
    }
}
