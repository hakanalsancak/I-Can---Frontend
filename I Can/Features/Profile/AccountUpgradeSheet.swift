import SwiftUI
import AuthenticationServices

struct AccountUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: OnboardingViewModel

    init() {
        let vm = OnboardingViewModel()
        if let user = AuthService.shared.currentUser {
            vm.selectedSport = user.sport
            vm.athleteName = user.fullName ?? ""
            vm.mantra = user.mantra ?? ""
            vm.notificationFrequency = user.notificationFrequency
            vm.selectedGender = user.gender ?? ""
            vm.selectedCountry = user.country ?? ""
            vm.team = user.team ?? ""
            vm.selectedCompetitionLevel = user.competitionLevel ?? ""
            vm.selectedPosition = user.position ?? ""
            vm.selectedPrimaryGoal = user.primaryGoal ?? ""
            vm.username = user.username ?? ""
            if let age = user.age { vm.selectedAge = age }
            vm.skipCompleteOnboardingAfterSocialAuth = true
        }
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(ColorTheme.accent)

                        Text("Sign In or Create Account")
                            .font(Typography.title2)
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .multilineTextAlignment(.center)

                        Text("Required to subscribe and restore your\npurchase on any device.")
                            .font(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

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
                        }
                    }
                    .padding(.horizontal, 24)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(ColorTheme.accent)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Typography.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 48)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                    }
                }
            }
        }
    }
}
