import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var notificationFrequency: Double
    @State private var mantra: String
    @State private var username: String
    @State private var usernameAvailable: Bool?
    @State private var usernameError: String?
    @State private var isSaving = false
    @State private var appearanceManager = AppearanceManager.shared
    @State private var checkTask: Task<Void, Never>?

    init() {
        let user = AuthService.shared.currentUser
        _notificationFrequency = State(initialValue: Double(user?.notificationFrequency ?? 1))
        _mantra = State(initialValue: user?.mantra ?? "")
        _username = State(initialValue: user?.username ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    appearanceSection

                    usernameSection

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
            .background(ColorTheme.background(appearanceManager.current.resolvedColorScheme).ignoresSafeArea())
            .preferredColorScheme(appearanceManager.current.resolvedColorScheme)
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

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("APPEARANCE")
                .sectionHeader(colorScheme)

            HStack(spacing: 8) {
                ForEach(AppAppearance.allCases, id: \.rawValue) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appearanceManager.current = option
                        }
                        HapticManager.selection()
                    } label: {
                        let isSelected = appearanceManager.current == option
                        VStack(spacing: 8) {
                            Image(systemName: option.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isSelected ? .white : ColorTheme.secondaryText(colorScheme))

                            Text(option.rawValue)
                                .font(.system(size: 12, weight: .bold).width(.condensed))
                                .foregroundColor(isSelected ? .white : ColorTheme.secondaryText(colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isSelected
                            ? AnyShapeStyle(ColorTheme.accentGradient)
                            : AnyShapeStyle(ColorTheme.cardBackground(colorScheme))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: isSelected ? ColorTheme.accent.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("USERNAME")
                .sectionHeader(colorScheme)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("@")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    TextField("username", text: $username)
                        .font(Typography.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: username) { _, newValue in
                            username = newValue.lowercased().replacingOccurrences(
                                of: "[^a-z0-9._]", with: "", options: .regularExpression
                            )
                            usernameAvailable = nil
                            usernameError = nil
                            checkTask?.cancel()
                            let current = username
                            let originalUsername = AuthService.shared.currentUser?.username ?? ""
                            guard current != originalUsername else { return }
                            checkTask = Task {
                                try? await Task.sleep(for: .milliseconds(500))
                                guard !Task.isCancelled, current == username else { return }
                                await checkUsernameAvailability()
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(usernameBorderColor, lineWidth: 1)
                )

                if let error = usernameError {
                    Text(error)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(.red)
                } else if usernameAvailable == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Available")
                    }
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(.green)
                }
            }
        }
    }

    private var usernameBorderColor: Color {
        if let available = usernameAvailable {
            return available ? .green.opacity(0.5) : .red.opacity(0.5)
        }
        return ColorTheme.separator(colorScheme)
    }

    private func checkUsernameAvailability() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            usernameError = trimmed.isEmpty ? nil : "At least 3 characters"
            usernameAvailable = false
            return
        }
        do {
            let result = try await FriendService.shared.checkUsername(trimmed)
            usernameAvailable = result.available
            usernameError = result.available ? nil : (result.error ?? "Username taken")
        } catch {
            usernameAvailable = nil
        }
    }

    private func saveSettings() async {
        isSaving = true
        do {
            let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
            let originalUsername = AuthService.shared.currentUser?.username ?? ""
            let usernameToSave = trimmedUsername != originalUsername && trimmedUsername.count >= 3 ? trimmedUsername : nil

            try await AuthService.shared.completeOnboarding(
                sport: AuthService.shared.currentUser?.sport ?? "soccer",
                mantra: mantra.isEmpty ? nil : mantra,
                notificationFrequency: Int(notificationFrequency),
                fullName: nil,
                age: nil,
                username: usernameToSave
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
