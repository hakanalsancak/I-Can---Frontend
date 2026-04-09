import SwiftUI

struct HeightWeightView: View {
    @Binding var height: Double // always cm
    @Binding var weight: Double // always kg
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var unitPref = UnitPreference.shared

    // Feet/inches local state for imperial picker
    @State private var feet: Int = 5
    @State private var inches: Int = 9

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("Height & Weight")
                        .font(.system(size: 28, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Visible on your profile for friends to see")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                HStack(spacing: 20) {
                    // Height column
                    VStack(spacing: 10) {
                        Text("HEIGHT")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .tracking(1)

                        unitToggle(
                            options: HeightUnit.allCases.map(\.label),
                            selected: HeightUnit.allCases.firstIndex(of: unitPref.heightUnit) ?? 0
                        ) { idx in
                            unitPref.heightUnit = HeightUnit.allCases[idx]
                            if unitPref.heightUnit == .feet {
                                let fi = UnitPreference.cmToFeetInches(height)
                                feet = fi.feet
                                inches = fi.inches
                            }
                        }

                        if unitPref.heightUnit == .cm {
                            Text("\(Int(height))")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundColor(ColorTheme.accent)
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.2), value: Int(height))

                            Text("cm")
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))

                            Picker("Height", selection: Binding(
                                get: { Int(height) },
                                set: { height = Double($0) }
                            )) {
                                ForEach(100...250, id: \.self) { v in
                                    Text("\(v)").tag(v)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: height) { HapticManager.selection() }
                        } else {
                            Text("\(feet)'\(inches)\"")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundColor(ColorTheme.accent)
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.2), value: feet * 12 + inches)

                            Text("ft / in")
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))

                            HStack(spacing: 4) {
                                Picker("Feet", selection: $feet) {
                                    ForEach(3...8, id: \.self) { v in
                                        Text("\(v)'").tag(v)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Picker("Inches", selection: $inches) {
                                    ForEach(0...11, id: \.self) { v in
                                        Text("\(v)\"").tag(v)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .onChange(of: feet) {
                                height = UnitPreference.feetInchesToCm(feet: feet, inches: inches)
                                HapticManager.selection()
                            }
                            .onChange(of: inches) {
                                height = UnitPreference.feetInchesToCm(feet: feet, inches: inches)
                                HapticManager.selection()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(ColorTheme.separator(colorScheme))
                        .frame(width: 1, height: 220)

                    // Weight column
                    VStack(spacing: 10) {
                        Text("WEIGHT")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .tracking(1)

                        unitToggle(
                            options: WeightUnit.allCases.map(\.label),
                            selected: WeightUnit.allCases.firstIndex(of: unitPref.weightUnit) ?? 0
                        ) { idx in
                            unitPref.weightUnit = WeightUnit.allCases[idx]
                        }

                        if unitPref.weightUnit == .kg {
                            Text("\(Int(weight))")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundColor(ColorTheme.accent)
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.2), value: Int(weight))

                            Text("kg")
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))

                            Picker("Weight", selection: Binding(
                                get: { Int(weight) },
                                set: { weight = Double($0) }
                            )) {
                                ForEach(30...200, id: \.self) { v in
                                    Text("\(v)").tag(v)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: weight) { HapticManager.selection() }
                        } else {
                            let lbs = Int(UnitPreference.kgToLbs(weight))
                            Text("\(lbs)")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundColor(ColorTheme.accent)
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.2), value: lbs)

                            Text("lbs")
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))

                            Picker("Weight", selection: Binding(
                                get: { Int(UnitPreference.kgToLbs(weight)) },
                                set: { weight = UnitPreference.lbsToKg(Double($0)) }
                            )) {
                                ForEach(66...440, id: \.self) { v in
                                    Text("\(v)").tag(v)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: weight) { HapticManager.selection() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
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
        .onAppear {
            let fi = UnitPreference.cmToFeetInches(height)
            feet = fi.feet
            inches = fi.inches
        }
    }

    // MARK: - Unit Toggle

    private func unitToggle(options: [String], selected: Int, onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { idx in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { onChange(idx) }
                    HapticManager.selection()
                } label: {
                    Text(options[idx])
                        .font(.system(size: 11, weight: .bold).width(.condensed))
                        .foregroundColor(idx == selected ? .white : ColorTheme.secondaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(idx == selected ? ColorTheme.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(ColorTheme.elevatedBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(width: 90)
    }
}
