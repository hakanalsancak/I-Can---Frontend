import Testing
import Foundation
@testable import I_Can

/// C-6: Premium status must persist across launches via UserDefaults
/// so premium users don't see a brief free-tier flash on cold start.
struct SubscriptionCacheTests {

    private let cacheKey = "cachedIsPremium"

    @Test("Setting isPremium true persists to UserDefaults")
    @MainActor
    func premiumCachedOnSet() {
        let service = SubscriptionService.shared

        // Set premium
        service.isPremium = true
        let cached = UserDefaults.standard.bool(forKey: cacheKey)
        #expect(cached == true)

        // Restore original state
        service.isPremium = false
    }

    @Test("Setting isPremium false persists to UserDefaults")
    @MainActor
    func nonPremiumCachedOnSet() {
        let service = SubscriptionService.shared

        service.isPremium = true
        service.isPremium = false
        let cached = UserDefaults.standard.bool(forKey: cacheKey)
        #expect(cached == false)
    }

    @Test("resetForSignOut clears the cached premium status")
    @MainActor
    func resetClearsCache() {
        let service = SubscriptionService.shared

        // Set premium then reset
        service.isPremium = true
        service.resetForSignOut()

        let cached = UserDefaults.standard.bool(forKey: cacheKey)
        #expect(cached == false)
        #expect(service.isPremium == false)
        #expect(service.statusChecked == false)
        #expect(service.subscriptionStatus == nil)
    }

    @Test("UserDefaults cache key is removed on sign-out, not just set to false")
    @MainActor
    func cacheKeyRemovedOnSignOut() {
        let service = SubscriptionService.shared

        service.isPremium = true
        service.resetForSignOut()

        // After removeObject, objectForKey returns nil (not false)
        let raw = UserDefaults.standard.object(forKey: cacheKey)
        #expect(raw == nil, "Cache key should be removed, not just set to false")
    }
}
