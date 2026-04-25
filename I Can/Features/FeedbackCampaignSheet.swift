import SwiftUI

struct FeedbackCampaignSheet: View {
    let campaign: String
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: Step = .rate
    @State private var liked: Bool? = nil
    @State private var message = ""
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var didFinalize = false
    @FocusState private var messageFocused: Bool

    private enum Step { case rate, detail, thanks }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch step {
                        case .rate: rateStep
                        case .detail: detailStep
                        case .thanks: thanksStep
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Quick Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        finalizeAndClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { submissionError != nil },
                set: { if !$0 { submissionError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(submissionError ?? "Please try again later.")
            }
            .interactiveDismissDisabled(isSubmitting)
        }
        .onDisappear { finalize() }
    }

    // MARK: - Step 1: Rate

    private var rateStep: some View {
        VStack(spacing: 22) {
            heroIcon(systemName: "heart.fill")

            VStack(spacing: 10) {
                Text("Are you enjoying I Can?")
                    .font(.system(size: 24, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text("Your honest take helps us shape what's next.")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 14) {
                rateButton(
                    title: "Loving it",
                    systemImage: "hand.thumbsup.fill",
                    isSelected: liked == true
                ) {
                    HapticManager.impact(.light)
                    liked = true
                    advanceTo(.detail)
                }

                rateButton(
                    title: "Not really",
                    systemImage: "hand.thumbsdown.fill",
                    isSelected: liked == false
                ) {
                    HapticManager.impact(.light)
                    liked = false
                    advanceTo(.detail)
                }
            }
            .padding(.top, 6)

            Button {
                finalizeAndClose()
            } label: {
                Text("Skip for now")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(.top, 4)
        }
        .padding(.top, 12)
    }

    private func rateButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [ColorTheme.accent, Color(hex: "358A90")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(ColorTheme.secondaryText(colorScheme))
                    )

                Text(title)
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? ColorTheme.accent.opacity(0.5) : ColorTheme.separator(colorScheme),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Detail

    private var detailStep: some View {
        VStack(spacing: 20) {
            heroIcon(systemName: "bubble.left.and.bubble.right.fill")

            VStack(spacing: 10) {
                Text(liked == true ? "What would make it even better?" : "What's not working for you?")
                    .font(.system(size: 22, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text("Improvements, features you'd like, bugs — anything goes.")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR THOUGHTS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .tracking(1)

                TextEditor(text: $message)
                    .font(.system(size: 15, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .scrollContentBackground(.hidden)
                    .focused($messageFocused)
                    .frame(minHeight: 130)
                    .padding(14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                messageFocused ? ColorTheme.accent.opacity(0.4) : ColorTheme.separator(colorScheme),
                                lineWidth: messageFocused ? 1.5 : 1
                            )
                    )
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Tell us what you'd improve, add, or fix…")
                                .font(.system(size: 15, weight: .regular).width(.condensed))
                                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 22)
                                .allowsHitTesting(false)
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("EMAIL")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .tracking(1)
                    Text("(optional, for replies)")
                        .font(.system(size: 11, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }

                TextField("your@email.com", text: $email)
                    .font(.system(size: 15, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                    )
            }

            Button {
                HapticManager.impact(.medium)
                Task { await submit() }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView().tint(.white).scaleEffect(0.9)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Send")
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

            Button {
                Task { await submitWithoutMessage() }
            } label: {
                Text(liked == nil ? "Skip" : "Just send my rating")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .disabled(isSubmitting)
        }
        .padding(.top, 12)
    }

    private var canSubmit: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Step 3: Thanks

    private var thanksStep: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "22C55E").opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "22C55E"))
            }

            VStack(spacing: 8) {
                Text("Thank You")
                    .font(.system(size: 24, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Your feedback helps us shape I Can.\nWe truly appreciate it.")
                    .font(.system(size: 15, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                finalizeAndClose()
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
        .padding(.top, 28)
    }

    // MARK: - Helpers

    private func heroIcon(systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(ColorTheme.accent.opacity(0.10))
                .frame(width: 72, height: 72)
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTheme.accent, Color(hex: "358A90")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func advanceTo(_ next: Step) {
        withAnimation(.easeInOut(duration: 0.25)) {
            step = next
        }
    }

    private func submit() async {
        await sendFeedback(includeFreeText: true)
    }

    private func submitWithoutMessage() async {
        await sendFeedback(includeFreeText: false)
    }

    private func sendFeedback(includeFreeText: Bool) async {
        isSubmitting = true
        let likedTag = liked == true ? "yes" : (liked == false ? "no" : "skipped")
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let body: String
        if includeFreeText && !trimmed.isEmpty {
            body = "[campaign:\(campaign) liked:\(likedTag)] \(trimmed)"
        } else {
            body = "[campaign:\(campaign) liked:\(likedTag)] (no additional message)"
        }

        do {
            try await FeedbackService.submit(
                message: body,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                type: "campaign"
            )
            HapticManager.notification(.success)
            AnalyticsManager.log("feedback_campaign_submitted")
            advanceTo(.thanks)
        } catch {
            HapticManager.notification(.error)
            submissionError = "Could not send feedback. Please check your connection and try again."
        }
        isSubmitting = false
    }

    private func finalize() {
        guard !didFinalize else { return }
        didFinalize = true
        onFinished()
    }

    private func finalizeAndClose() {
        finalize()
        dismiss()
    }
}
