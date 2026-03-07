import SwiftUI

struct PageHeader: View {
    let title: String
    var trailing: AnyView? = nil
    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String) {
        self.title = title
    }

    init(_ title: String, @ViewBuilder trailing: () -> some View) {
        self.title = title
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                if let trailing {
                    trailing
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)
        }
        .background(ColorTheme.background(colorScheme))
    }
}
