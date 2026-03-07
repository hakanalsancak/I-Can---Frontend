import SwiftUI
import AuthenticationServices

struct AccountCreationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(Typography.title)
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Save your progress and access\nyour data across devices")
                        .font(Typography.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 10) {
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
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        Task { await viewModel.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 8) {
                            Image("GoogleLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                                .font(Typography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                        )
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 24)

                dividerRow

                VStack(spacing: 10) {
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

                VStack(spacing: 16) {
                    PrimaryButton(
                        title: "Create Account",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.email.isEmpty || viewModel.password.isEmpty
                    ) {
                        Task { await viewModel.registerWithEmail() }
                    }

                    Button {
                        Task { await viewModel.skipAccountCreation() }
                    } label: {
                        Text("Skip for now")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private var dividerRow: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 1)
            Text("or")
                .font(Typography.caption)
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
            )
    }
}
