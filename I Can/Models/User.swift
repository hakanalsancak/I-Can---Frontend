import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    var username: String?
    let fullName: String?
    var age: Int?
    var gender: String?
    var country: String?
    var sport: String
    var mantra: String?
    var notificationFrequency: Int
    var team: String?
    var competitionLevel: String?
    var position: String?
    var primaryGoal: String?
    var onboardingCompleted: Bool
    var createdAt: String?

    var isGuest: Bool {
        guard let email = email else { return true }
        return email.hasPrefix("guest_") && (email.hasSuffix("@ican.app") || email.hasSuffix("@guest.ican.app"))
    }
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let fullName: String?
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct AppleSignInRequest: Encodable {
    let identityToken: String
    let fullName: FullName?

    struct FullName: Encodable {
        let givenName: String?
        let familyName: String?
    }
}

struct GoogleSignInRequest: Encodable {
    let idToken: String
}

struct OnboardingRequest: Encodable {
    let sport: String
    let mantra: String?
    let notificationFrequency: Int
    let fullName: String?
    let age: Int?
    let country: String?
    let gender: String?
    let team: String?
    let competitionLevel: String?
    let position: String?
    let primaryGoal: String?
    let username: String?
}
