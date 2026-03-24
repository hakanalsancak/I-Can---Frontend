import SwiftUI

struct UsernameEntryView: View {
    @Binding var username: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    @State private var isAvailable: Bool?
    @State private var errorText: String?
    @State private var checkTask: Task<Void, Never>?
    @State private var networkError = false

    private var isValid: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces).lowercased()
        return trimmed.count >= 3 && (isAvailable == true || networkError)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Create Your Username")
                        .font(.system(size: 28, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("This is how other athletes will find you")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Text("@")
                            .font(.system(size: 22, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))

                        TextField("username", text: $username)
                            .font(.system(size: 22, weight: .bold).width(.condensed))
                            .textContentType(.username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($isFocused)
                            .onChange(of: username) { _, newValue in
                                username = newValue.lowercased().replacingOccurrences(
                                    of: "[^a-z0-9._]", with: "", options: .regularExpression
                                )
                                isAvailable = nil
                                errorText = nil
                                networkError = false
                                checkTask?.cancel()
                                let current = username
                                checkTask = Task {
                                    try? await Task.sleep(for: .milliseconds(500))
                                    guard !Task.isCancelled, current == username else { return }
                                    await checkAvailability()
                                }
                            }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                statusBorderColor,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 40)

                    if let error = errorText {
                        Text(error)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(networkError ? .orange : .red)
                    } else if isAvailable == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Username available")
                                .foregroundColor(.green)
                        }
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                    }
                }

                VStack(spacing: 4) {
                    Text("Examples: alex23 · emma.soccer · james_guard")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme).opacity(0.7))
                }
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

                    PrimaryButton(
                        title: "Continue",
                        isDisabled: !isValid
                    ) {
                        withAnimation { onNext() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
        .onAppear { isFocused = true }
    }

    private var statusBorderColor: Color {
        if let available = isAvailable {
            return available ? .green.opacity(0.5) : .red.opacity(0.5)
        }
        return isFocused ? ColorTheme.accent.opacity(0.4) : ColorTheme.separator(colorScheme)
    }

    private func checkAvailability() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            if !trimmed.isEmpty {
                errorText = "Username must be at least 3 characters"
            }
            isAvailable = false
            return
        }

        do {
            let result = try await FriendService.shared.checkUsername(trimmed)
            if let error = result.error {
                errorText = error
                isAvailable = false
            } else {
                isAvailable = result.available
                if !result.available {
                    errorText = "Username is already taken"
                }
            }
        } catch {
            if !Task.isCancelled {
                errorText = "Could not verify username. You can still continue."
                networkError = true
            }
        }
    }
}
