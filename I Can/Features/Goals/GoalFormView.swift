import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var goalType = "weekly"
    @State private var title = ""
    @State private var description = ""
    let onCreate: (String, String, String?) -> Void

    private let types: [(String, String, String, Color)] = [
        ("weekly", "Weekly", "calendar", Color(hex: "3B82F6")),
        ("monthly", "Monthly", "calendar.circle", Color(hex: "8B5CF6")),
        ("yearly", "Yearly", "star.circle", Color(hex: "F97316")),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    goalTypeSection
                    goalTitleSection
                    descriptionSection
                    createButton
                }
                .padding(20)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Goal")
                        .font(.system(size: 17, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
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

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GOAL TYPE")
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            HStack(spacing: 10) {
                ForEach(types, id: \.0) { type in
                    Button {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            goalType = type.0
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.2)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(goalType == type.0 ? .white : type.3)
                            Text(type.1)
                                .font(.system(size: 12, weight: .bold).width(.condensed))
                                .foregroundColor(goalType == type.0 ? .white : ColorTheme.primaryText(colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(goalType == type.0 ? AnyShapeStyle(type.3) : AnyShapeStyle(ColorTheme.cardBackground(colorScheme)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    goalType == type.0
                                    ? type.3.opacity(0.5)
                                    : ColorTheme.separator(colorScheme),
                                    lineWidth: goalType == type.0 ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var goalTitleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT'S YOUR GOAL?")
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            TextField(placeholderForType, text: $title)
                .font(.system(size: 15, weight: .semibold).width(.condensed))
                .padding(16)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                )
        }
    }

    private var placeholderForType: String {
        switch goalType {
        case "weekly": return "e.g. Train 5 times this week"
        case "monthly": return "e.g. Improve endurance consistently"
        case "yearly": return "e.g. Make the starting lineup"
        default: return "e.g. Train 5 times"
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DETAILS (OPTIONAL)")
                .font(.system(size: 10, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))

            TextField("Add more context...", text: $description, axis: .vertical)
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .lineLimit(3...5)
                .padding(16)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                )
        }
    }

    private var createButton: some View {
        PrimaryButton(
            title: "Create Goal",
            isDisabled: title.isEmpty
        ) {
            onCreate(goalType, title, description.isEmpty ? nil : description)
            dismiss()
        }
        .padding(.top, 4)
    }
}
