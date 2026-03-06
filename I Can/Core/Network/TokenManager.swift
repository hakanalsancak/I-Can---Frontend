import Foundation

final class TokenManager: Sendable {
    static let shared = TokenManager()

    private let accessTokenKey = "ican_access_token"
    private let refreshTokenKey = "ican_refresh_token"

    var isAuthenticated: Bool {
        accessToken != nil
    }

    var accessToken: String? {
        KeychainHelper.readString(forKey: accessTokenKey)
    }

    var refreshToken: String? {
        KeychainHelper.readString(forKey: refreshTokenKey)
    }

    func saveTokens(access: String, refresh: String) {
        KeychainHelper.save(access, forKey: accessTokenKey)
        KeychainHelper.save(refresh, forKey: refreshTokenKey)
    }

    func clearTokens() {
        KeychainHelper.delete(forKey: accessTokenKey)
        KeychainHelper.delete(forKey: refreshTokenKey)
    }

    private init() {}
}
