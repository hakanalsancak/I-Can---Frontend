import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var notificationFrequency: Double
    @State private var mantra: String
    @State private var isSaving = false

    init() {
        let user = AuthService.shared.currentUser
        _notificationFrequency = State(initialValue: Double(user?.notificationFrequency ?? 1))
        _mantra = State(initialValue: user?.mantra ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR MANTRA")
                            .sectionHeader(colorScheme)

                        TextField("Enter your mantra...", text: $mantra, axis: .vertical)
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
                        Text("MOTIVATIONAL NOTIFICATIONS")
                            .sectionHeader(colorScheme)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Per day")
                                    .font(Typography.body)
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                                Spacer()
                                Text("\(Int(notificationFrequency))")
                                    .font(Typography.number(20))
                                    .foregroundColor(ColorTheme.accent)
                            }
                            Slider(value: $notificationFrequency, in: 0...3, step: 1)
                                .tint(ColorTheme.accent)
                        }
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ABOUT")
                            .sectionHeader(colorScheme)

                        HStack {
                            Text("Version")
                                .font(Typography.body)
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Spacer()
                            Text("1.0.0")
                                .font(Typography.subheadline)
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveSettings() }
                    }
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.accent)
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveSettings() async {
        isSaving = true
        do {
            try await AuthService.shared.completeOnboarding(
                sport: AuthService.shared.currentUser?.sport ?? "soccer",
                mantra: mantra.isEmpty ? nil : mantra,
                notificationFrequency: Int(notificationFrequency)
            )
            try await NotificationService.shared.updatePreferences(
                frequency: Int(notificationFrequency)
            )
            dismiss()
        } catch {
            // Handle error
        }
        isSaving = false
    }
}
