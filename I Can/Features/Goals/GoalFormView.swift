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
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Type")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        HStack(spacing: 8) {
                            ForEach(types, id: \.0) { type in
                                Button {
                                    HapticManager.selection()
                                    goalType = type.0
                                } label: {
                                    Text(type.1)
                                        .font(Typography.subheadline)
                                        .foregroundColor(goalType == type.0 ? .white : ColorTheme.primaryText(colorScheme))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(goalType == type.0 ? ColorTheme.accent : ColorTheme.cardBackground(colorScheme))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        TextField("e.g. Train 5 times", text: $title)
                            .font(Typography.body)
                            .padding(16)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (optional)")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        TextField("Add details...", text: $description, axis: .vertical)
                            .font(Typography.body)
                            .lineLimit(3...5)
                            .padding(16)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        .foregroundColor(ColorTheme.accent)
                }
            }
        }
    }
}
