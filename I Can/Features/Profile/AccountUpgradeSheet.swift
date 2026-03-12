import SwiftUI
import AuthenticationServices

struct AccountUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: OnboardingViewModel
    @State private var mode: AuthMode = .choose
    @State private var errorMessage: String?

    enum AuthMode {
        case choose
        case signIn
        case createAccount
    }

    init() {
        let vm = OnboardingViewModel()
        if let user = AuthService.shared.currentUser {
            vm.selectedSport = user.sport
            vm.athleteName = user.fullName ?? ""
            vm.mantra = user.mantra ?? ""
            vm.notificationFrequency = user.notificationFrequency
            vm.fullName = user.fullName ?? ""
            vm.selectedGender = user.gender ?? ""
            vm.selectedCountry = user.country ?? ""
            vm.team = user.team ?? ""
            vm.selectedCompetitionLevel = user.competitionLevel ?? ""
            vm.selectedPosition = user.position ?? ""
            vm.selectedPrimaryGoal = user.primaryGoal ?? ""
            vm.username = user.username ?? ""
            if let age = user.age { vm.selectedAge = age }
        }
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .choose:
                    chooseView
                case .signIn:
                    signInView
                case .createAccount:
                    createAccountView
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if mode != .choose {
                        Button {
                            mode = .choose
                            errorMessage = nil
                            viewModel.errorMessage = nil
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        }
                    }
                }
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
            .onChange(of: AuthService.shared.currentUser?.isGuest) { _, isGuest in
                if isGuest == false {
                    dismiss()
                }
            }
            .onChange(of: mode) { _, newMode in
                viewModel.skipCompleteOnboardingAfterSocialAuth = (newMode == .signIn)
            }
            .onAppear {
                viewModel.skipCompleteOnboardingAfterSocialAuth = (mode == .signIn)
            }
        }
    }

    private var chooseView: some View {
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
                    Button {
                        mode = .signIn
                        viewModel.errorMessage = nil
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                            Text("Sign In")
                                .font(.system(size: 16, weight: .bold).width(.condensed))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .padding(16)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    Button {
                        mode = .createAccount
                        viewModel.errorMessage = nil
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18))
                            Text("Create Account")
                                .font(.system(size: 16, weight: .bold).width(.condensed))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [ColorTheme.accent, Color(hex: "358A90")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private var signInView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("Welcome Back")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Sign in to continue")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 24)

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
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    Rectangle().fill(ColorTheme.separator(colorScheme)).frame(height: 1)
                    Text("or").font(Typography.caption).foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    Rectangle().fill(ColorTheme.separator(colorScheme)).frame(height: 1)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 10) {
                    TextField("Email", text: $viewModel.loginEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(ICanTextFieldStyle())

                    SecureField("Password", text: $viewModel.loginPassword)
                        .textContentType(.password)
                        .textFieldStyle(ICanTextFieldStyle())
                }
                .padding(.horizontal, 24)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Typography.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    PrimaryButton(
                        title: "Sign In",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.loginEmail.isEmpty || viewModel.loginPassword.isEmpty
                    ) {
                        Task { await viewModel.loginWithEmail() }
                    }

                    Button {
                        mode = .createAccount
                        viewModel.errorMessage = nil
                    } label: {
                        Text("Don't have an account? Create one")
                            .font(.system(size: 13, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private var createAccountView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Text("Save your progress and subscribe")
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                .padding(.top, 24)

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
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    Rectangle().fill(ColorTheme.separator(colorScheme)).frame(height: 1)
                    Text("or").font(Typography.caption).foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    Rectangle().fill(ColorTheme.separator(colorScheme)).frame(height: 1)
                }
                .padding(.horizontal, 24)

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

                VStack(spacing: 12) {
                    PrimaryButton(
                        title: "Create Account",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.email.isEmpty || viewModel.password.isEmpty
                    ) {
                        Task { await viewModel.registerWithEmail() }
                    }

                    Button {
                        mode = .signIn
                        viewModel.errorMessage = nil
                    } label: {
                        Text("Already have an account? Sign in")
                            .font(.system(size: 13, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}
