import Foundation
import AuthenticationServices

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    var currentUser: User?
    private(set) var isAuthenticated = TokenManager.shared.isAuthenticated
    var hasCompletedOnboarding: Bool { currentUser?.onboardingCompleted ?? false }
    var justCompletedOnboarding = false

    func register(email: String, password: String, fullName: String?, activate: Bool = true) async throws {
        let request = RegisterRequest(email: email, password: password, fullName: fullName)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.register, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        if activate { isAuthenticated = true }
    }

    @discardableResult
    func signInWithApple(identityToken: String, fullName: PersonNameComponents?, activate: Bool = true) async throws -> AuthResponse {
        let name = fullName.map {
            AppleSignInRequest.FullName(givenName: $0.givenName, familyName: $0.familyName)
        }
        let request = AppleSignInRequest(identityToken: identityToken, fullName: name)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.apple, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        if activate { isAuthenticated = true }
        return response
    }

    @discardableResult
    func signInWithGoogle(idToken: String, activate: Bool = true) async throws -> AuthResponse {
        let request = GoogleSignInRequest(idToken: idToken)
        let response: AuthResponse = try await APIClient.shared.request(
            APIEndpoints.Auth.google, method: "POST", body: request, authenticated: false
        )
        TokenManager.shared.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        if activate { isAuthenticated = true }
        return response
    }

    /// Call after deferred auth + onboarding to finalize the session.
    func activateSession() {
        isAuthenticated = true
    }

    /// Discard saved tokens/user when a deferred auth flow fails.
    func deactivatePendingSession() {
        TokenManager.shared.clearTokens()
        currentUser = nil
    }

    func linkAppleAccount(identityToken: String, fullName: PersonNameComponents?) async throws {
        let name = fullName.map {
            AppleSignInRequest.FullName(givenName: $0.givenName, familyName: $0.familyName)
        }
        let request = AppleSignInRequest(identityToken: identityToken, fullName: name)
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.linkApple, method: "PUT", body: request
        )
        currentUser = user
    }

    func linkGoogleAccount(idToken: String) async throws {
        let request = GoogleSignInRequest(idToken: idToken)
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.linkGoogle, method: "PUT", body: request
        )
        currentUser = user
    }

    func completeOnboarding(
        sport: String, mantra: String?, notificationFrequency: Int,
        fullName: String?, age: Int?, country: String? = nil,
        gender: String? = nil, team: String? = nil,
        competitionLevel: String? = nil, position: String? = nil,
        primaryGoal: String? = nil, username: String? = nil,
        height: Double? = nil, weight: Double? = nil
    ) async throws {
        let request = OnboardingRequest(
            sport: sport, mantra: mantra, notificationFrequency: notificationFrequency,
            fullName: fullName, age: age, country: country,
            gender: gender, team: team, competitionLevel: competitionLevel,
            position: position, primaryGoal: primaryGoal, username: username,
            height: height, weight: weight
        )
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.onboarding, method: "PUT", body: request
        )
        currentUser = user
        justCompletedOnboarding = true
    }

    func loadProfile() async throws {
        let user: User = try await APIClient.shared.request(APIEndpoints.Auth.profile)
        currentUser = user
    }

    /// Sets the user's country from device locale if not already set.
    /// Called explicitly during onboarding so the user is aware.
    func setCountryIfNeeded() async {
        guard let user = currentUser, user.country == nil,
              let deviceCountry = Locale.current.region?.identifier else { return }
        let body = ["country": deviceCountry]
        if let updated: User = try? await APIClient.shared.request(
            APIEndpoints.Auth.profile, method: "PUT", body: body
        ) {
            currentUser = updated
        }
    }

    func updatePrivacy(hideHeightWeight: Bool) async throws {
        struct PrivacyUpdate: Encodable { let hideHeightWeight: Bool }
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.profile, method: "PUT", body: PrivacyUpdate(hideHeightWeight: hideHeightWeight)
        )
        currentUser = user
    }

    func updateMantra(_ mantra: String) async throws {
        let body = ["mantra": mantra]
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.profile, method: "PUT", body: body
        )
        currentUser = user
    }

    func updateProfile(
        fullName: String? = nil,
        username: String? = nil,
        sport: String? = nil,
        team: String? = nil,
        position: String? = nil,
        mantra: String? = nil,
        height: Double? = nil,
        weight: Double? = nil
    ) async throws {
        var body: [String: String] = [:]
        if let fullName { body["fullName"] = fullName }
        if let username { body["username"] = username.lowercased() }
        if let sport { body["sport"] = sport }
        if let team { body["team"] = team }
        if let position { body["position"] = position }
        if let mantra { body["mantra"] = mantra }
        if let height { body["height"] = String(height) }
        if let weight { body["weight"] = String(weight) }

        guard !body.isEmpty else { return }
        let user: User = try await APIClient.shared.request(
            APIEndpoints.Auth.profile, method: "PUT", body: body
        )
        currentUser = user
    }

    func deleteAccount(confirmUsername: String) async throws {
        let body = ["username": confirmUsername.lowercased()]
        let _: [String: String] = try await APIClient.shared.request(
            APIEndpoints.Auth.deleteAccount, method: "DELETE", body: body
        )
        signOut()
    }

    func signOut() {
        // Capture tokens before clearing so the logout request can still use them
        let refreshToken = TokenManager.shared.refreshToken
        let accessToken = TokenManager.shared.accessToken

        // Clear local state immediately so the UI reacts right away
        ChatService.shared.clearMessages()
        TokenManager.shared.clearTokens()
        currentUser = nil
        isAuthenticated = false
        SubscriptionService.shared.resetForSignOut()

        // Best-effort: revoke refresh token on the server so it can't be reused after logout.
        // Uses the captured access token directly since tokens are already cleared from Keychain.
        if let refreshToken, let accessToken {
            let logoutURL = URL(string: APIEndpoints.baseURL + APIEndpoints.Auth.logout)
            Task.detached { @Sendable in
                struct LogoutBody: Encodable { let refreshToken: String }
                let body = LogoutBody(refreshToken: refreshToken)
                guard let url = logoutURL else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = try? JSONEncoder().encode(body)
                let session = URLSession(configuration: .default)
                let _ = try? await session.data(for: request)
            }
        }
    }

    private init() {}
}
