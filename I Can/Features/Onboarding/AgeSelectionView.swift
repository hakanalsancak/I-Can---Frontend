import SwiftUI

struct AgeSelectionView: View {
    @Binding var age: Int
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let minAge = 14
    private let maxAge = 50

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("How Old Are You?")
                        .font(.system(size: 28, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("This helps us tailor coaching to your level")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Text("\(age)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.accent)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: age)

                Picker("Age", selection: $age) {
                    ForEach(minAge...maxAge, id: \.self) { value in
                        Text("\(value)")
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 60)
                .onChange(of: age) {
                    HapticManager.selection()
                }
            }

            Spacer()
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

                    PrimaryButton(title: "Continue") {
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
