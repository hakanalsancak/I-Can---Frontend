import SwiftUI
import AuthenticationServices
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct AccountUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var signInVM = OnboardingViewModel()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignInWarning = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    signUpSection
                    divider
                    signInSection

                    if isLoading {
                        ProgressView()
                            .tint(ColorTheme.accent)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 48)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .alert("Switch Account?", isPresented: $showSignInWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Sign In", role: .destructive) {
                    performSignIn()
                }
            } message: {
                Text("Your guest data will be lost. You'll be signed into your existing account.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 44, weight: .medium))
                .foregroundColor(ColorTheme.accent)

            Text("Create Your Account")
                .font(.system(size: 24, weight: .heavy).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text("Required to subscribe and sync\nyour data across devices")
                .font(.system(size: 14, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.top, 40)
    }

    // MARK: - Sign Up

    private var signUpSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ColorTheme.accent)
                Text("SIGN UP")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.accent)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Create a new account. Your current progress will be kept.")
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task { await handleAppleLink(with: authorization) }
                    case .failure:
                        errorMessage = "Apple Sign-In was cancelled"
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .cornerRadius(14)

                Button {
                    Task { await handleGoogleLink() }
                } label: {
                    HStack(spacing: 8) {
                        Image("GoogleLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        Text("Sign up with Google")
                            .font(.system(size: 16, weight: .semibold).width(.condensed))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                Text("SIGN IN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Already have an account? Sign in here. Guest data will be lost.")
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        signInVM.signInAuthorization = authorization
                        showSignInWarning = true
                    case .failure:
                        errorMessage = "Apple Sign-In was cancelled"
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .cornerRadius(14)

                Button {
                    signInVM.pendingGoogleSignIn = true
                    showSignInWarning = true
                } label: {
                    HStack(spacing: 8) {
                        Image("GoogleLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .font(.system(size: 16, weight: .semibold).width(.condensed))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 0.5)
            Text("or")
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Sign Up Handlers (link to existing guest account)

    private func handleAppleLink(with authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Apple Sign-In failed"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.linkAppleAccount(
                identityToken: token, fullName: credential.fullName
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    private func handleGoogleLink() async {
        #if canImport(GoogleSignIn) && canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                isLoading = false
                return
            }
            try await AuthService.shared.linkGoogleAccount(idToken: idToken)
            dismiss()
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
        #else
        errorMessage = "Google Sign-In is not available"
        #endif
    }

    // MARK: - Sign In Handlers

    private func performSignIn() {
        Task {
            isLoading = true
            errorMessage = nil

            if let authorization = signInVM.signInAuthorization {
                signInVM.skipCompleteOnboardingAfterSocialAuth = true
                await signInVM.signInWithApple(authorization: authorization)
                signInVM.signInAuthorization = nil
            } else if signInVM.pendingGoogleSignIn {
                signInVM.skipCompleteOnboardingAfterSocialAuth = true
                await signInVM.signInWithGoogle()
                signInVM.pendingGoogleSignIn = false
            }

            if let error = signInVM.errorMessage {
                errorMessage = error
            } else {
                dismiss()
            }
            isLoading = false
        }
    }
}
