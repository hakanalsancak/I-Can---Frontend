import Foundation
import AuthenticationServices

@Observable
final class AuthService {
    static let shared = AuthService()

    var currentUser: User?
    private(set) var isAuthenticated = TokenManager.shared.isAuthenticated
    var hasCompletedOnboarding: Bool { currentUser?.onboardingCompleted ?? false }

    func register(email: String, password: String, fullName: String?) async throws {
        let request = RegisterRequest(email: email, password: password, fullName: fullName)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.register, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        isAuthenticated = true
    }

    func login(email: String, password: String) async throws {
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.login, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        isAuthenticated = true
    }

    func signInWithApple(identityToken: String, fullName: PersonNameComponents?) async throws {
        let name = fullName.map {
            AppleSignInRequest.FullName(givenName: $0.givenName, familyName: $0.familyName)
        }
        let request = AppleSignInRequest(identityToken: identityToken, fullName: name)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.apple, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        isAuthenticated = true
    }

    func signInWithGoogle(idToken: String) async throws {
        let request = GoogleSignInRequest(idToken: idToken)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.google, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        isAuthenticated = true
    }

    func completeOnboarding(sport: String, mantra: String?, notificationFrequency: Int, fullName: String?, age: Int?, country: String? = nil) async throws {
        let request = OnboardingRequest(sport: sport, mantra: mantra, notificationFrequency: notificationFrequency, fullName: fullName, age: age, country: country)
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.onboarding, method: "PUT", body: request
        )
        currentUser = user
    }

    func loadProfile() async throws {
        let user: User = try await APIClient.shared.request(APIEndpoints.Auth.profile)
        currentUser = user

        if user.country == nil, let deviceCountry = Locale.current.region?.identifier {
            let body = ["country": deviceCountry]
            let updated: User = try await APIClient.shared.request(
                APIEndpoints.Auth.profile, method: "PUT", body: body
            )
            currentUser = updated
        }
    }

    func updateMantra(_ mantra: String) async throws {
        let body = ["mantra": mantra]
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.profile, method: "PUT", body: body
        )
        currentUser = user
    }

    func signOut() {
        TokenManager.shared.clearTokens()
        currentUser = nil
        isAuthenticated = false
        SubscriptionService.shared.resetForSignOut()
    }

    private init() {}
}
