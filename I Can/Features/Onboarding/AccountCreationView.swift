import SwiftUI
import AuthenticationServices

struct AccountCreationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var appleSignInHelper = AppleSignInHelper()

    private let benefits = [
        ("icloud.and.arrow.up", "Sync across all devices"),
        ("chart.bar.fill", "Unlock AI coaching reports"),
        ("person.2.fill", "Connect with friends"),
        ("bell.badge.fill", "Personalized notifications"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {

                // MARK: - Hero
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(ColorTheme.accent.opacity(0.12))
                            .frame(width: 88, height: 88)
                            .scaleEffect(appeared ? 1 : 0.5)
                            .opacity(appeared ? 1 : 0)

                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(ColorTheme.accent)
                            .scaleEffect(appeared ? 1 : 0.5)
                            .opacity(appeared ? 1 : 0)
                    }

                    VStack(spacing: 6) {
                        Text("Create Your Account")
                            .font(.system(size: 26, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        Text("Sign in to save your progress and\naccess your data across devices")
                            .font(.system(size: 15, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }
                .padding(.top, 28)

                // MARK: - Benefits
                VStack(spacing: 10) {
                    ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                        HStack(spacing: 14) {
                            Image(systemName: benefit.0)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ColorTheme.accent)
                                .frame(width: 34, height: 34)
                                .background(ColorTheme.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                            Text(benefit.1)
                                .font(.system(size: 15, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            Spacer()

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "22C55E"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.easeOut(duration: 0.45).delay(0.15 + Double(index) * 0.08), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                // MARK: - Sign In Buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            do {
                                let authorization = try await appleSignInHelper.signIn()
                                await viewModel.signInWithApple(authorization: authorization)
                            } catch let error as ASAuthorizationError where error.code == .canceled {
                                // User cancelled
                            } catch {
                                viewModel.errorMessage = "Apple Sign-In failed"
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20, weight: .medium))
                            Text("Sign in with Apple")
                                .font(.system(size: 16, weight: .semibold).width(.condensed))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(colorScheme == .dark ? .white : .black)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

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
                .animation(.easeOut(duration: 0.5).delay(0.55), value: appeared)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(ColorTheme.accent)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                // MARK: - Separator + Skip
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
                        Task { await viewModel.skipAccountCreation() }
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 15, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Text("You can sign in later from your profile")
                        .font(.system(size: 12, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: appeared)

                // MARK: - Back
                Button {
                    withAnimation { viewModel.previousStep() }
                } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}
