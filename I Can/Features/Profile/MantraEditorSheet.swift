import SwiftUI

struct MantraEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var mantra: String
    let onSave: (String) -> Void

    init(currentMantra: String, onSave: @escaping (String) -> Void) {
        self._mantra = State(initialValue: currentMantra)
        self.onSave = onSave
    }

    private let suggestions: [(quote: String, athlete: String)] = [
        ("Limits are an illusion.", "Michael Jordan"),
        ("Impossible is nothing.", "Muhammad Ali"),
        ("Stay focused.", "Usain Bolt"),
        ("Rise to the challenge.", "Kobe Bryant"),
        ("Stick to it.", "Serena Williams"),
        ("Dream bigger.", "Michael Phelps"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Your Mantra")
                            .font(.system(size: 22, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("A personal phrase to keep you focused")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 8)

                    TextField("Enter your mantra...", text: $mantra, axis: .vertical)
                        .font(.system(size: 17, weight: .semibold).width(.condensed))
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                        )

                    PrimaryButton(
                        title: "Save Mantra",
                        isDisabled: mantra.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        onSave(mantra.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("INSPIRED BY THE GREATS")
                            .font(.system(size: 10, weight: .heavy).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))

                        ForEach(suggestions, id: \.quote) { suggestion in
                            Button {
                                mantra = suggestion.quote
                                HapticManager.impact(.light)
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\"\(suggestion.quote)\"")
                                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                                        Text("— \(suggestion.athlete)")
                                            .font(.system(size: 11, weight: .medium).width(.condensed))
                                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                    }

                                    Spacer()

                                    if mantra == suggestion.quote {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(ColorTheme.accent)
                                    }
                                }
                                .padding(14)
                                .background(
                                    mantra == suggestion.quote
                                    ? ColorTheme.subtleAccent(colorScheme)
                                    : ColorTheme.cardBackground(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            mantra == suggestion.quote
                                            ? ColorTheme.accent.opacity(0.3)
                                            : ColorTheme.separator(colorScheme),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
