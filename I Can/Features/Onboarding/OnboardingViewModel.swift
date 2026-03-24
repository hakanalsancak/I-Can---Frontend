import Foundation
import AuthenticationServices
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case nameEntry
    case ageSelection
    case genderSelection
    case nationalitySelection
    case sportSelection
    case teamEntry
    case competitionLevel
    case positionSelection
    case primaryGoal
    case usernameEntry
    case mantraCreation
    case notificationFrequency
    case accountCreation
}

@MainActor
@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var skipCompleteOnboardingAfterSocialAuth = false
    var selectedSport: String = ""
    var athleteName: String = ""
    var selectedAge: Int = 18
    var selectedGender: String = ""
    var selectedCountry: String = ""
    var team: String = ""
    var selectedCompetitionLevel: String = ""
    var selectedPosition: String = ""
    var selectedPrimaryGoal: String = ""
    var username: String = ""
    var mantra: String = ""
    var notificationFrequency: Int = 1
    var isLoading = false
    var errorMessage: String?
    var showLogin = false
    var signInAuthorization: ASAuthorization?
    var pendingGoogleSignIn = false

    let sports = [
        ("soccer", "Soccer", "sportscourt"),
        ("basketball", "Basketball", "basketball"),
        ("tennis", "Tennis", "tennisball"),
        ("football", "Football", "football"),
        ("boxing", "Boxing", "figure.boxing"),
        ("cricket", "Cricket", "cricket.ball"),
    ]

    let mantraExamples: [(quote: String, athlete: String)] = [
        ("Limits are an illusion.", "Michael Jordan"),
        ("Impossible is nothing.", "Muhammad Ali"),
        ("Stay focused.", "Usain Bolt"),
        ("Rise to the challenge.", "Kobe Bryant"),
        ("Stick to it.", "Serena Williams"),
        ("Dream bigger.", "Michael Phelps"),
    ]

    func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func signInWithApple(authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Apple Sign-In failed"
            return
        }

        isLoading = true
        errorMessage = nil
        let wasAuthenticated = AuthService.shared.isAuthenticated
        do {
            try await AuthService.shared.signInWithApple(
                identityToken: token, fullName: credential.fullName,
                activate: skipCompleteOnboardingAfterSocialAuth
            )
            if skipCompleteOnboardingAfterSocialAuth || showLogin {
                AnalyticsManager.log("user_signed_in", parameters: ["method": "apple"])
                AuthService.shared.activateSession()
            } else {
                if AuthService.shared.currentUser?.onboardingCompleted == true {
                    AuthService.shared.deactivatePendingSession()
                    errorMessage = "An account already exists with this Apple ID. Please log in instead, or use a different email to create a new account."
                    isLoading = false
                    return
                }
                AnalyticsManager.log("user_signed_up", parameters: ["method": "apple"])
                try await completeOnboarding()
                AuthService.shared.activateSession()
            }
        } catch {
            if !wasAuthenticated {
                AuthService.shared.deactivatePendingSession()
            }
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func signInWithGoogle() async {
        #if canImport(GoogleSignIn) && canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            return
        }

        isLoading = true
        errorMessage = nil
        let wasAuthenticated = AuthService.shared.isAuthenticated

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                isLoading = false
                return
            }

            try await AuthService.shared.signInWithGoogle(
                idToken: idToken,
                activate: skipCompleteOnboardingAfterSocialAuth
            )
            if skipCompleteOnboardingAfterSocialAuth || showLogin {
                AnalyticsManager.log("user_signed_in", parameters: ["method": "google"])
                AuthService.shared.activateSession()
            } else {
                if AuthService.shared.currentUser?.onboardingCompleted == true {
                    AuthService.shared.deactivatePendingSession()
                    errorMessage = "An account already exists with this Google account. Please log in instead, or use a different email to create a new account."
                    isLoading = false
                    return
                }
                AnalyticsManager.log("user_signed_up", parameters: ["method": "google"])
                try await completeOnboarding()
                AuthService.shared.activateSession()
            }
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                errorMessage = nil
            } else {
                if !wasAuthenticated {
                    AuthService.shared.deactivatePendingSession()
                }
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
        #else
        errorMessage = "Google Sign-In is not available"
        #endif
    }

    func skipAccountCreation() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.register(
                email: "guest_\(UUID().uuidString.prefix(8))@guest.ican.app",
                password: UUID().uuidString,
                fullName: athleteName.isEmpty ? nil : athleteName,
                activate: false
            )
            AnalyticsManager.log("user_signed_up", parameters: ["method": "guest"])
            try await completeOnboarding()
            AuthService.shared.activateSession()
        } catch {
            AuthService.shared.deactivatePendingSession()
            errorMessage = "Could not connect to server. Please try again."
        }
        isLoading = false
    }

    private func completeOnboarding() async throws {
        if !selectedSport.isEmpty {
            AnalyticsManager.log("sport_selected", parameters: ["sport": selectedSport])
            if !mantra.isEmpty {
                AnalyticsManager.log("mantra_created")
            }
            let country = selectedCountry.isEmpty ? Locale.current.region?.identifier : selectedCountry
            try await AuthService.shared.completeOnboarding(
                sport: selectedSport,
                mantra: mantra.isEmpty ? nil : mantra,
                notificationFrequency: notificationFrequency,
                fullName: athleteName.isEmpty ? nil : athleteName,
                age: selectedAge,
                country: country,
                gender: selectedGender.isEmpty ? nil : selectedGender,
                team: team.trimmingCharacters(in: .whitespaces).isEmpty ? nil : team.trimmingCharacters(in: .whitespaces),
                competitionLevel: selectedCompetitionLevel.isEmpty ? nil : selectedCompetitionLevel,
                position: selectedPosition.isEmpty ? nil : selectedPosition,
                primaryGoal: selectedPrimaryGoal.isEmpty ? nil : selectedPrimaryGoal,
                username: username.trimmingCharacters(in: .whitespaces).isEmpty ? nil : username.trimmingCharacters(in: .whitespaces).lowercased()
            )
        }
    }
}
