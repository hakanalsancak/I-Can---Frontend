import SwiftUI

struct SleepLogView: View {
    let existingData: SleepData?
    let onSave: (SleepData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var sleepTime = Date()
    @State private var wakeTime = Date()

    init(existingData: SleepData?, onSave: @escaping (SleepData) -> Void) {
        self.existingData = existingData
        self.onSave = onSave

        if let d = existingData {
            let sleepDate = Self.dateFromTimeString(d.sleepTime) ?? Self.defaultSleepTime()
            let wakeDate = Self.dateFromTimeString(d.wakeTime) ?? Self.defaultWakeTime()
            _sleepTime = State(initialValue: sleepDate)
            _wakeTime = State(initialValue: wakeDate)
        } else {
            _sleepTime = State(initialValue: Self.defaultSleepTime())
            _wakeTime = State(initialValue: Self.defaultWakeTime())
        }
    }

    private static func defaultSleepTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func defaultWakeTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func dateFromTimeString(_ time: String) -> Date? {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = parts[0]
        components.minute = parts[1]
        return Calendar.current.date(from: components)
    }

    private var timeString: (sleep: String, wake: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return (formatter.string(from: sleepTime), formatter.string(from: wakeTime))
    }

    private var sleepData: SleepData {
        let t = timeString
        return SleepData(sleepTime: t.sleep, wakeTime: t.wake)
    }

    private var durationText: String {
        sleepData.durationFormatted
    }

    private var durationHours: Double {
        sleepData.durationHours
    }

    private var durationColor: Color {
        if durationHours >= 7 && durationHours <= 9 { return ColorTheme.nutrition }
        if durationHours >= 6 { return ColorTheme.training }
        return Color(hex: "EF4444")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Duration Display
                    VStack(spacing: 8) {
                        Text(durationText)
                            .font(Typography.number(56))
                            .foregroundColor(durationColor)

                        Text("Total Sleep")
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))

                        // Quality indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(durationColor)
                                .frame(width: 8, height: 8)
                            Text(sleepQualityLabel)
                                .font(.system(size: 12, weight: .bold).width(.condensed))
                                .foregroundColor(durationColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(durationColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)

                    // Sleep Time Picker
                    timePickerCard(
                        title: "WENT TO SLEEP",
                        icon: "moon.fill",
                        iconColor: Color(hex: "6366F1"),
                        time: $sleepTime
                    )

                    // Wake Time Picker
                    timePickerCard(
                        title: "WOKE UP",
                        icon: "sunrise.fill",
                        iconColor: Color(hex: "F59E0B"),
                        time: $wakeTime
                    )

                    // Save Button
                    Button {
                        HapticManager.impact(.medium)
                        save()
                    } label: {
                        Text("SAVE SLEEP")
                            .font(.system(size: 15, weight: .heavy).width(.condensed))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ColorTheme.sleepGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: ColorTheme.sleep.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.sleep)
                        Text("Sleep")
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

    private var sleepQualityLabel: String {
        if durationHours >= 8 { return "Excellent" }
        if durationHours >= 7 { return "Good" }
        if durationHours >= 6 { return "Fair" }
        return "Poor"
    }

    private func save() {
        let t = timeString
        let data = SleepData(sleepTime: t.sleep, wakeTime: t.wake)
        onSave(data)
        dismiss()
    }

    private func timePickerCard(
        title: String, icon: String, iconColor: Color, time: Binding<Date>
    ) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Spacer()
            }

            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .clipped()
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }
}
