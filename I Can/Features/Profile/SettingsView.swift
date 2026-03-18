import SwiftUI
import MessageUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var notificationFrequency: Double
    @State private var isSaving = false
    @State private var appearanceManager = AppearanceManager.shared
    @State private var showSignOutAlert = false
    @State private var showDeleteSection = false
    @State private var deleteUsername = ""
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showMailComposer = false
    @State private var saveError: String?

    private var currentUsername: String {
        AuthService.shared.currentUser?.username ?? ""
    }

    private var canDelete: Bool {
        deleteUsername.lowercased() == currentUsername.lowercased() && !currentUsername.isEmpty
    }

    init() {
        let user = AuthService.shared.currentUser
        _notificationFrequency = State(initialValue: Double(user?.notificationFrequency ?? 1))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let saveError {
                        Text(saveError)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    appearanceSection
                    notificationSection
                    contactSection
                    aboutSection
                    signOutSection
                    deleteAccountSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
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
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    dismiss()
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        AuthService.shared.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(recipient: "contact@alsancar.co.uk", subject: "I Can App - Support")
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("APPEARANCE")

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

    // MARK: - Notifications

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("NOTIFICATIONS")

            VStack(spacing: 12) {
                HStack {
                    Text("Motivational per day")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
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
    }

    // MARK: - Contact

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("CONTACT")

            VStack(spacing: 0) {
                settingsRow(
                    icon: "envelope.fill",
                    iconColor: ColorTheme.accent,
                    title: "Email Us",
                    subtitle: "contact@alsancar.co.uk"
                ) {
                    if MFMailComposeViewController.canSendMail() {
                        showMailComposer = true
                    } else if let url = URL(string: "mailto:contact@alsancar.co.uk") {
                        UIApplication.shared.open(url)
                    }
                }

                Divider()
                    .padding(.leading, 54)
                    .opacity(0.4)

                settingsRow(
                    icon: "globe",
                    iconColor: Color(hex: "3B82F6"),
                    title: "Website",
                    subtitle: "icanathlete.com"
                ) {
                    if let url = URL(string: "https://icanathlete.com") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ABOUT")

            HStack {
                Text("Version")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Sign Out

    private var signOutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ACCOUNT")

            Button {
                HapticManager.impact(.medium)
                showSignOutAlert = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "F97316").opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "F97316"))
                    }

                    Text("Sign Out")
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Delete Account

    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("DANGER ZONE")

            VStack(spacing: 0) {
                Button {
                    HapticManager.impact(.medium)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDeleteSection.toggle()
                        deleteUsername = ""
                        deleteError = nil
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .font(.system(size: 15, weight: .semibold).width(.condensed))
                                .foregroundColor(.red)
                            Text("Permanently delete all your data")
                                .font(.system(size: 11, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            .rotationEffect(.degrees(showDeleteSection ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if showDeleteSection {
                    Divider().padding(.horizontal, 16).opacity(0.4)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("This action is irreversible. All your entries, reports, streaks, and friends will be permanently deleted.")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .lineSpacing(2)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type your username to confirm:")
                                .font(.system(size: 12, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))

                            HStack(spacing: 4) {
                                Text("@")
                                    .font(.system(size: 15, weight: .bold).width(.condensed))
                                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                                TextField(currentUsername, text: $deleteUsername)
                                    .font(.system(size: 15, weight: .medium).width(.condensed))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(
                                        canDelete ? Color.red.opacity(0.4) : ColorTheme.separator(colorScheme),
                                        lineWidth: 1
                                    )
                            )
                        }

                        if let error = deleteError {
                            Text(error)
                                .font(.system(size: 12, weight: .medium).width(.condensed))
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await deleteAccount() }
                        } label: {
                            HStack(spacing: 6) {
                                if isDeleting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Delete My Account")
                                        .font(.system(size: 14, weight: .bold).width(.condensed))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canDelete ? Color.red : Color.red.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canDelete || isDeleting)
                    }
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.red.opacity(showDeleteSection ? 0.15 : 0), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Reusable

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(ColorTheme.secondaryText(colorScheme))
            .tracking(1)
    }

    private func settingsRow(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func saveSettings() async {
        isSaving = true
        saveError = nil
        do {
            try await AuthService.shared.completeOnboarding(
                sport: AuthService.shared.currentUser?.sport ?? "soccer",
                mantra: AuthService.shared.currentUser?.mantra,
                notificationFrequency: Int(notificationFrequency),
                fullName: nil,
                age: nil
            )
            try await NotificationService.shared.updatePreferences(
                frequency: Int(notificationFrequency)
            )
            dismiss()
        } catch {
            saveError = "Failed to save settings. Please try again."
        }
        isSaving = false
    }

    private func deleteAccount() async {
        isDeleting = true
        deleteError = nil
        do {
            try await AuthService.shared.deleteAccount(confirmUsername: deleteUsername)
            dismiss()
        } catch {
            deleteError = "Failed to delete account. Please try again."
        }
        isDeleting = false
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}
