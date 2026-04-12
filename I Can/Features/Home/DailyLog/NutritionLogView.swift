import SwiftUI

struct NutritionLogView: View {
    let existingData: NutritionData?
    let onSave: (NutritionData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var breakfast = ""
    @State private var lunch = ""
    @State private var dinner = ""
    @State private var snacks = ""
    @State private var drinks = ""

    init(existingData: NutritionData?, onSave: @escaping (NutritionData) -> Void) {
        self.existingData = existingData
        self.onSave = onSave
        if let d = existingData {
            _breakfast = State(initialValue: d.breakfast ?? "")
            _lunch = State(initialValue: d.lunch ?? "")
            _dinner = State(initialValue: d.dinner ?? "")
            _snacks = State(initialValue: d.snacks ?? "")
            _drinks = State(initialValue: d.drinks ?? "")
        }
    }

    private var hasAtLeastOneMeal: Bool {
        !breakfast.trimmingCharacters(in: .whitespaces).isEmpty ||
        !lunch.trimmingCharacters(in: .whitespaces).isEmpty ||
        !dinner.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Breakfast
                    mealCard(
                        title: "BREAKFAST",
                        icon: "sunrise.fill",
                        iconColor: Color(hex: "F59E0B"),
                        placeholder: "What did you have for breakfast?",
                        text: $breakfast
                    )

                    // Lunch
                    mealCard(
                        title: "LUNCH",
                        icon: "sun.max.fill",
                        iconColor: ColorTheme.nutrition,
                        placeholder: "What did you have for lunch?",
                        text: $lunch
                    )

                    // Dinner
                    mealCard(
                        title: "DINNER",
                        icon: "moon.fill",
                        iconColor: Color(hex: "6366F1"),
                        placeholder: "What did you have for dinner?",
                        text: $dinner
                    )

                    // Optional: Snacks & Drinks
                    VStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ColorTheme.nutrition)
                            Text("EXTRAS (OPTIONAL)")
                                .font(.system(size: 11, weight: .heavy).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        mealField(
                            label: "Snacks",
                            icon: "carrot.fill",
                            placeholder: "Protein bar, fruits, nuts...",
                            text: $snacks
                        )

                        mealField(
                            label: "Drinks",
                            icon: "drop.fill",
                            placeholder: "Water, protein shake, coffee...",
                            text: $drinks
                        )
                    }
                    .padding(16)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)

                    // Save Button
                    Button {
                        HapticManager.impact(.medium)
                        save()
                    } label: {
                        Text("SAVE NUTRITION")
                            .font(.system(size: 15, weight: .heavy).width(.condensed))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                hasAtLeastOneMeal
                                    ? AnyShapeStyle(ColorTheme.nutritionGradient)
                                    : AnyShapeStyle(ColorTheme.nutrition.opacity(0.4))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: ColorTheme.nutrition.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!hasAtLeastOneMeal)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.nutrition)
                        Text("Nutrition")
                            .font(.system(size: 17, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func save() {
        let data = NutritionData(
            breakfast: breakfast.isEmpty ? nil : breakfast,
            lunch: lunch.isEmpty ? nil : lunch,
            dinner: dinner.isEmpty ? nil : dinner,
            snacks: snacks.isEmpty ? nil : snacks,
            drinks: drinks.isEmpty ? nil : drinks
        )
        onSave(data)
        dismiss()
    }

    private func mealCard(
        title: String, icon: String, iconColor: Color,
        placeholder: String, text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineLimit(2...4)
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func mealField(
        label: String, icon: String, placeholder: String, text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text(label)
                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 14, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineLimit(1...3)
                .padding(10)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
