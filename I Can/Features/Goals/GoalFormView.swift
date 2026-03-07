import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var goalType = "weekly"
    @State private var title = ""
    @State private var description = ""
    let onCreate: (String, String, String?) -> Void

    private let types = [
        ("weekly", "Weekly"),
        ("monthly", "Monthly"),
        ("yearly", "Yearly"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GOAL TYPE")
                            .sectionHeader(colorScheme)

                        HStack(spacing: 8) {
                            ForEach(types, id: \.0) { type in
                                Button {
                                    HapticManager.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        goalType = type.0
                                    }
                                } label: {
                                    Text(type.1)
                                        .font(Typography.subheadline)
                                        .foregroundColor(goalType == type.0 ? .white : ColorTheme.primaryText(colorScheme))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            goalType == type.0
                                            ? AnyShapeStyle(ColorTheme.accentGradient)
                                            : AnyShapeStyle(ColorTheme.cardBackground(colorScheme))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            goalType != type.0
                                            ? RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                                            : nil
                                        )
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("GOAL")
                            .sectionHeader(colorScheme)

                        TextField("e.g. Train 5 times", text: $title)
                            .font(Typography.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("DESCRIPTION (OPTIONAL)")
                            .sectionHeader(colorScheme)

                        TextField("Add details...", text: $description, axis: .vertical)
                            .font(Typography.body)
                            .lineLimit(3...5)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                            )
                    }

                    PrimaryButton(
                        title: "Create Goal",
                        isDisabled: title.isEmpty
                    ) {
                        onCreate(goalType, title, description.isEmpty ? nil : description)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
        }
    }
}
