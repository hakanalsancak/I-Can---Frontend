import StoreKit
import SwiftUI

@MainActor
enum ReviewManager {
    private static let sessionCountKey = "authenticatedSessionCount"
    private static let hasRequestedKey = "hasRequestedReview"
    private static let triggerSessionCount = 2
    private static var countedThisLaunch = false

    /// Records that the user is in an authenticated, onboarded session for this app launch
    /// and presents the App Store rating prompt on their second such session.
    static func recordAuthenticatedSession(request: RequestReviewAction) {
        guard !countedThisLaunch else { return }
        countedThisLaunch = true

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: hasRequestedKey) else { return }

        let next = defaults.integer(forKey: sessionCountKey) + 1
        defaults.set(next, forKey: sessionCountKey)
        guard next >= triggerSessionCount else { return }

        defaults.set(true, forKey: hasRequestedKey)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            request()
        }
    }
}
