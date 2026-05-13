import SwiftUI

struct NotificationFrequencyView: View {
    @Binding var frequency: Int
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var motivationalTimes: [Date] = NotificationFrequencyView.loadMotivationalTimes(frequency: 3)
    @State private var streakReminderTime: Date = NotificationFrequencyView.loadStreakTime()

    private let options = [
        (0, "None", "No notifications"),
        (1, "1x", "Once per day"),
        (2, "2x", "Twice per day"),
        (3, "3x", "Three times per day"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Stay Motivated")
                            .font(Typography.title)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Text("How many motivational reminders\nwould you like per day?")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 8) {
                        ForEach(options, id: \.0) { option in
                            Button {
                                HapticManager.impact(.light)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    frequency = option.0
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Text(option.1)
                                        .font(Typography.number(16, weight: .semibold))
                                        .foregroundColor(frequency == option.0 ? .white : ColorTheme.accent)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            frequency == option.0
                                            ? AnyShapeStyle(ColorTheme.accentGradient)
                                            : AnyShapeStyle(ColorTheme.subtleAccent(colorScheme))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                    Text(option.2)
                                        .font(Typography.body)
                                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                                    Spacer()

                                    if frequency == option.0 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                                            .foregroundColor(ColorTheme.accent)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    frequency == option.0
                                    ? ColorTheme.subtleAccent(colorScheme)
                                    : ColorTheme.cardBackground(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(
                                            frequency == option.0 ? ColorTheme.accent.opacity(0.4) : ColorTheme.separator(colorScheme),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)

                    if frequency > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pick your times")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                                .tracking(1)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                ForEach(0..<frequency, id: \.self) { slot in
                                    timeRow(
                                        label: slotLabel(slot: slot, total: frequency),
                                        selection: Binding(
                                            get: { motivationalTimes[slot] },
                                            set: { motivationalTimes[slot] = $0 }
                                        )
                                    )
                                    if slot < frequency - 1 {
                                        Divider().padding(.leading, 16).opacity(0.4)
                                    }
                                }
                            }
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                        }
                        .padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily log reminder")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .tracking(1)
                            .padding(.horizontal, 4)

                        timeRow(label: "Reminder time", selection: $streakReminderTime)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)

                        Text("We'll nudge you if you haven't logged yet.")
                            .font(Typography.caption)
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 8) {
                        Text("\"I Can stay focused under pressure.\"")
                            .font(Typography.callout)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .italic()
                        Text("Example notification")
                            .font(Typography.caption)
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(ColorTheme.subtleAccent(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 24)
                }
            }

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
                        persistTimes()
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

    private func timeRow(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(ColorTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func slotLabel(slot: Int, total: Int) -> String {
        if total == 1 { return "Reminder" }
        let ordinals = ["1st", "2nd", "3rd"]
        return "\(ordinals[slot]) reminder"
    }

    private func persistTimes() {
        let comps = motivationalTimes.prefix(max(frequency, 0)).map { date -> DateComponents in
            Calendar.current.dateComponents([.hour, .minute], from: date)
        }
        NotificationService.shared.setMotivationalTimes(Array(comps))
        let streakComps = Calendar.current.dateComponents([.hour, .minute], from: streakReminderTime)
        NotificationService.shared.setStreakReminderTime(streakComps)
    }

    private static func loadMotivationalTimes(frequency: Int) -> [Date] {
        let calendar = Calendar.current
        let stored = NotificationService.shared.motivationalTimes(frequency: frequency)
        return (0..<frequency).map { idx in
            let comps = idx < stored.count ? stored[idx] : DateComponents(hour: 9, minute: 0)
            return calendar.date(bySettingHour: comps.hour ?? 9, minute: comps.minute ?? 0, second: 0, of: Date()) ?? Date()
        }
    }

    private static func loadStreakTime() -> Date {
        let comps = NotificationService.shared.streakReminderTime()
        return Calendar.current.date(bySettingHour: comps.hour ?? 20, minute: comps.minute ?? 30, second: 0, of: Date()) ?? Date()
    }
}
