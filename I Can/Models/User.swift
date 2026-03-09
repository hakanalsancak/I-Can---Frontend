import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    var age: Int?
    var country: String?
    var sport: String
    var mantra: String?
    var notificationFrequency: Int
    var onboardingCompleted: Bool
    var createdAt: String?
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let fullName: String?
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
}
