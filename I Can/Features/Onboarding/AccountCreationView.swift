import SwiftUI
import AuthenticationServices

struct AccountCreationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Save your progress and access\nyour data across devices")
                        .font(Typography.body)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            Task { await viewModel.signInWithApple(authorization: authorization) }
                        case .failure:
                            viewModel.errorMessage = "Apple Sign-In was cancelled"
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        // Google Sign-In requires GoogleSignIn SDK
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continue with Google")
                                .font(Typography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 24)

                dividerRow

                VStack(spacing: 12) {
                    TextField("Full Name", text: $viewModel.fullName)
                        .textContentType(.name)
                        .textFieldStyle(ICanTextFieldStyle())

                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(ICanTextFieldStyle())

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .textFieldStyle(ICanTextFieldStyle())
                }
                .padding(.horizontal, 24)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Typography.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }

                PrimaryButton(
                    title: "Create Account",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.email.isEmpty || viewModel.password.isEmpty
                ) {
                    Task { await viewModel.registerWithEmail() }
                }
                .padding(.horizontal, 24)

                Button("Skip for now") {
                    Task { await viewModel.skipAccountCreation() }
                }
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .padding(.bottom, 40)
            }
        }
    }

    private var dividerRow: some View {
        HStack {
            Rectangle()
                .fill(ColorTheme.cardBackground(colorScheme))
                .frame(height: 1)
            Text("or")
                .font(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
            Rectangle()
                .fill(ColorTheme.cardBackground(colorScheme))
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
    }
}

struct ICanTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Typography.body)
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
