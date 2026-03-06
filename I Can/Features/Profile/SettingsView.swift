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
            ScrollView {
                VStack(spacing: 20) {
                    mantraSection
                    notificationSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ColorTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveSettings() }
                    }
                    .foregroundColor(ColorTheme.accent)
                    .disabled(isSaving)
                }
            }
        }
    }

    private var mantraSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Mantra")
                .font(Typography.headline)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            TextField("Enter your mantra...", text: $mantra, axis: .vertical)
                .font(Typography.body)
                .padding(16)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Motivational Notifications")
                .font(Typography.headline)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            CardView {
                VStack(spacing: 12) {
                    HStack {
                        Text("Notifications per day")
                            .font(Typography.body)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Spacer()
                        Text("\(Int(notificationFrequency))")
                            .font(Typography.title3)
                            .foregroundColor(ColorTheme.accent)
                            .monospacedDigit()
                    }
                    Slider(value: $notificationFrequency, in: 0...3, step: 1)
                        .tint(ColorTheme.accent)
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(Typography.headline)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            CardView {
                VStack(spacing: 12) {
                    HStack {
                        Text("Version")
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .font(Typography.body)
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
