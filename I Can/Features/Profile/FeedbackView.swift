import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var message = ""
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case message, email }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection

                    messageSection

                    emailSection

                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again later.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.accent, Color(hex: "358A90")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("We'd love to hear from you")
                .font(.system(size: 15, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Message

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR FEEDBACK")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .tracking(1)

            TextEditor(text: $message)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .scrollContentBackground(.hidden)
                .focused($focusedField, equals: .message)
                .frame(minHeight: 140)
                .padding(14)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            focusedField == .message
                                ? ColorTheme.accent.opacity(0.4)
                                : ColorTheme.separator(colorScheme),
                            lineWidth: focusedField == .message ? 1.5 : 1
                        )
                )
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                .overlay(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("What would you like to see improved or added?")
                            .font(.system(size: 15, weight: .regular).width(.condensed))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Email

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("EMAIL")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .tracking(1)
                Text("(optional)")
                    .font(.system(size: 11, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }

            TextField("your@email.com", text: $email)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .email)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            focusedField == .email
                                ? ColorTheme.accent.opacity(0.4)
                                : ColorTheme.separator(colorScheme),
                            lineWidth: focusedField == .email ? 1.5 : 1
                        )
                )
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            HapticManager.impact(.medium)
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Submit Feedback")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                canSubmit
                    ? AnyShapeStyle(LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "358A90")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    : AnyShapeStyle(ColorTheme.accent.opacity(0.3))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: canSubmit ? ColorTheme.accent.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSubmitting)
        .padding(.top, 4)
    }

    private var canSubmit: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            ColorTheme.background(colorScheme).opacity(0.95).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "22C55E").opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "22C55E"))
                }

                VStack(spacing: 8) {
                    Text("Thank You")
                        .font(.system(size: 24, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Your feedback helps us improve I Can.\nWe truly appreciate it.")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold).width(.condensed))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ColorTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Submit Action

    private func submit() async {
        isSubmitting = true
        do {
            try await FeedbackService.submit(
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            HapticManager.notification(.success)
            AnalyticsManager.log("feedback_submitted")
            withAnimation(.easeOut(duration: 0.3)) {
                showSuccess = true
            }
            message = ""
            email = ""
        } catch {
            HapticManager.notification(.error)
            errorMessage = "Could not send feedback. Please check your connection and try again."
        }
        isSubmitting = false
    }
}
