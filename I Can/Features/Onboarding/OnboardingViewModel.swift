import Foundation
import AuthenticationServices

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case sportSelection
    case mantraCreation
    case notificationFrequency
    case accountCreation
}

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var selectedSport: String = ""
    var mantra: String = ""
    var notificationFrequency: Int = 1
    var email: String = ""
    var password: String = ""
    var fullName: String = ""
    var isLoading = false
    var errorMessage: String?

    let sports = [
        ("soccer", "Soccer", "sportscourt"),
        ("basketball", "Basketball", "basketball"),
        ("tennis", "Tennis", "tennisball"),
        ("football", "Football", "football"),
        ("boxing", "Boxing", "figure.boxing"),
        ("cricket", "Cricket", "cricket.ball"),
    ]

    let mantraExamples = [
        "I stay calm under pressure.",
        "I give 100% every day.",
        "I trust my preparation.",
        "I thrive in big moments.",
        "I learn from every challenge.",
    ]

    func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func registerWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in email and password"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.register(
                email: email, password: password, fullName: fullName.isEmpty ? nil : fullName
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

    func skipAccountCreation() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.register(
                email: "guest_\(UUID().uuidString.prefix(8))@ican.app",
                password: UUID().uuidString,
                fullName: nil
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
                notificationFrequency: notificationFrequency
            )
        }
    }
}
