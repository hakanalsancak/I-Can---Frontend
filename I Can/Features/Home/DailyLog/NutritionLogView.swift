import SwiftUI

struct NutritionLogView: View {
    let existingData: NutritionData?
    let onSave: (NutritionData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var breakfast = ""
    @State private var lunch = ""
    @State private var dinner = ""
    @State private var snacks: [String] = []
    @State private var snackInput = ""
    @State private var drinks = ""
    @State private var waterAmount: String = ""
    @State private var waterUnit: WaterUnit = WaterUnit.localeDefault
    @FocusState private var waterFocused: Bool

    init(existingData: NutritionData?, onSave: @escaping (NutritionData) -> Void) {
        self.existingData = existingData
        self.onSave = onSave
        if let d = existingData {
            _breakfast = State(initialValue: d.breakfast ?? "")
            _lunch = State(initialValue: d.lunch ?? "")
            _dinner = State(initialValue: d.dinner ?? "")
            let parsedSnacks = (d.snacks ?? "")
                .split(whereSeparator: { $0 == "," || $0 == "\n" })
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            _snacks = State(initialValue: parsedSnacks)
            _drinks = State(initialValue: d.drinks ?? "")
            if let amount = d.waterAmount, amount > 0 {
                let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", amount)
                    : String(format: "%g", amount)
                _waterAmount = State(initialValue: formatted)
            }
            if let unitRaw = d.waterUnit, let unit = WaterUnit(rawValue: unitRaw) {
                _waterUnit = State(initialValue: unit)
            }
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

                    // Water (separate section)
                    waterCard

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

                        snacksField

                        mealField(
                            label: "Drinks",
                            icon: "cup.and.saucer.fill",
                            placeholder: "Protein shake, coffee, juice...",
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

    private var parsedWaterAmount: Double? {
        let normalized = waterAmount
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty, let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private var waterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "3B82F6"))
                Text("WATER")
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
                if let amount = parsedWaterAmount {
                    Text(waterUnit.format(amount))
                        .font(.system(size: 11, weight: .bold).width(.condensed))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }

            HStack(spacing: 10) {
                TextField("0", text: $waterAmount)
                    .keyboardType(.decimalPad)
                    .focused($waterFocused)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Picker("Unit", selection: $waterUnit) {
                    ForEach(WaterUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "3B82F6"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 8) {
                ForEach(quickAddOptions, id: \.0) { item in
                    Button {
                        HapticManager.impact(.light)
                        addQuickAmount(item.0)
                    } label: {
                        Text(item.1)
                            .font(.system(size: 12, weight: .semibold).width(.condensed))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "3B82F6").opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private var quickAddOptions: [(Double, String)] {
        switch waterUnit {
        case .liters: return [(0.25, "+0.25L"), (0.5, "+0.5L"), (1, "+1L")]
        case .milliliters: return [(250, "+250mL"), (500, "+500mL"), (1000, "+1L")]
        case .fluidOunces: return [(8, "+8oz"), (16, "+16oz"), (32, "+32oz")]
        case .cups: return [(1, "+1 cup"), (2, "+2 cups"), (4, "+4 cups")]
        }
    }

    private func addQuickAmount(_ amount: Double) {
        let current = parsedWaterAmount ?? 0
        let total = current + amount
        waterAmount = total.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", total)
            : String(format: "%g", total)
    }

    private func save() {
        let amount = parsedWaterAmount
        let data = NutritionData(
            breakfast: breakfast.isEmpty ? nil : breakfast,
            lunch: lunch.isEmpty ? nil : lunch,
            dinner: dinner.isEmpty ? nil : dinner,
            snacks: snacks.isEmpty ? nil : snacks.joined(separator: ", "),
            drinks: drinks.isEmpty ? nil : drinks,
            waterAmount: amount,
            waterUnit: amount == nil ? nil : waterUnit.rawValue
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

    private func addSnack() {
        let trimmed = snackInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !snacks.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            snacks.append(trimmed)
        }
        snackInput = ""
        HapticManager.selection()
    }

    private var snacksField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "carrot.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text("Snacks")
                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            if !snacks.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(snacks, id: \.self) { snack in
                        HStack(spacing: 4) {
                            Text(snack)
                                .font(.system(size: 12, weight: .semibold).width(.condensed))
                            Button {
                                snacks.removeAll { $0 == snack }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                        }
                        .foregroundColor(ColorTheme.nutrition)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ColorTheme.nutrition.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Add a snack...", text: $snackInput)
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .submitLabel(.done)
                    .onSubmit { addSnack() }

                Button {
                    addSnack()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(
                            snackInput.trimmingCharacters(in: .whitespaces).isEmpty
                                ? ColorTheme.tertiaryText(colorScheme)
                                : ColorTheme.nutrition
                        )
                }
                .disabled(snackInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
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
