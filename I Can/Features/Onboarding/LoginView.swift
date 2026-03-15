import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: - Hero
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.12))
                        .frame(width: 100, height: 100)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Sign in to continue your journey")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.45).delay(0.1), value: appeared)
            }

            Spacer()

            // MARK: - Sign In Buttons
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
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task { await viewModel.signInWithGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        Image("GoogleLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.system(size: 16, weight: .semibold).width(.condensed))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
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
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)

            // MARK: - Loading & Error
            if viewModel.isLoading {
                ProgressView()
                    .tint(ColorTheme.accent)
                    .padding(.top, 20)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            // MARK: - Switch to Sign Up
            VStack(spacing: 16) {
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

                Button {
                    withAnimation {
                        viewModel.errorMessage = nil
                        viewModel.showLogin = false
                    }
                } label: {
                    Text("Don't have an account? **Sign Up**")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}
