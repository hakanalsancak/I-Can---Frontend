import Foundation
import AuthenticationServices
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case sportSelection
    case nameEntry
    case ageSelection
    case mantraCreation
    case notificationFrequency
    case accountCreation
}

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var selectedSport: String = ""
    var athleteName: String = ""
    var selectedAge: Int = 18
    var mantra: String = ""
    var notificationFrequency: Int = 1
    var email: String = ""
    var password: String = ""
    var fullName: String = ""
    var isLoading = false
    var errorMessage: String?
    var showLogin = false
    var loginEmail = ""
    var loginPassword = ""

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

    func loginWithEmail() async {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Please fill in email and password"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.login(email: loginEmail, password: loginPassword)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func registerWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in email and password"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let nameToUse = athleteName.isEmpty ? (fullName.isEmpty ? nil : fullName) : athleteName
            try await AuthService.shared.register(
                email: email, password: password, fullName: nameToUse
            )
            try await completeOnboarding()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
        do {
            try await AuthService.shared.signInWithApple(
                identityToken: token, fullName: credential.fullName
            )
            try await completeOnboarding()
        } catch {
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

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                isLoading = false
                return
            }

            try await AuthService.shared.signInWithGoogle(idToken: idToken)
            try await completeOnboarding()
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

    func skipAccountCreation() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.register(
                email: "guest_\(UUID().uuidString.prefix(8))@ican.app",
                password: UUID().uuidString,
                fullName: athleteName.isEmpty ? nil : athleteName
            )
            try await completeOnboarding()
        } catch {
            errorMessage = "Could not connect to server. Make sure the backend is running on localhost:3000."
            print("Skip account error: \(error)")
        }
        isLoading = false
    }

    private func completeOnboarding() async throws {
        if !selectedSport.isEmpty {
            try await AuthService.shared.completeOnboarding(
                sport: selectedSport,
                mantra: mantra.isEmpty ? nil : mantra,
                notificationFrequency: notificationFrequency,
                fullName: athleteName.isEmpty ? nil : athleteName,
                age: selectedAge
            )
        }
    }
}
