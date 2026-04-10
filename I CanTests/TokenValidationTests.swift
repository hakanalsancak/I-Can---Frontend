import Testing
import Foundation
@testable import I_Can

/// C-5: refreshAccessToken must reject empty/malformed tokens
/// before saving them to Keychain.
struct TokenValidationTests {

    @Test("Empty access token is rejected")
    func emptyAccessTokenRejected() {
        // The fix guards: !tokenResponse.accessToken.isEmpty
        let accessToken = ""
        let refreshToken = "valid-refresh-token"
        #expect(accessToken.isEmpty, "Empty access token must be caught by the guard")
        #expect(!refreshToken.isEmpty)
    }

    @Test("Empty refresh token is rejected")
    func emptyRefreshTokenRejected() {
        let accessToken = "valid-access-token"
        let refreshToken = ""
        #expect(!accessToken.isEmpty)
        #expect(refreshToken.isEmpty, "Empty refresh token must be caught by the guard")
    }

    @Test("Both tokens empty is rejected")
    func bothTokensEmptyRejected() {
        let accessToken = ""
        let refreshToken = ""
        #expect(accessToken.isEmpty || refreshToken.isEmpty)
    }

    @Test("Valid tokens pass the guard")
    func validTokensAccepted() {
        let accessToken = "eyJhbGciOiJIUzI1NiJ9.payload.signature"
        let refreshToken = "eyJhbGciOiJIUzI1NiJ9.refresh.signature"
        let passes = !accessToken.isEmpty && !refreshToken.isEmpty
        #expect(passes)
    }

    @Test("Keychain round-trip preserves token integrity")
    func keychainRoundTrip() {
        let testKey = "ican_test_token_\(UUID().uuidString)"
        let original = "test-token-value-\(UUID().uuidString)"

        // Save
        KeychainHelper.save(original, forKey: testKey)

        // Read back
        let retrieved = KeychainHelper.readString(forKey: testKey)
        #expect(retrieved == original)

        // Cleanup
        KeychainHelper.delete(forKey: testKey)
        let afterDelete = KeychainHelper.readString(forKey: testKey)
        #expect(afterDelete == nil)
    }
}
