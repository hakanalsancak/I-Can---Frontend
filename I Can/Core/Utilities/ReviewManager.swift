import StoreKit
import SwiftUI

enum ReviewManager {
    @AppStorage("entrySubmitCount") private static var entrySubmitCount: Int = 0
    @AppStorage("lastReviewRequestDate") private static var lastReviewRequestDateInterval: Double = 0

    private static let milestoneCounts: Set<Int> = [3, 10, 25, 50, 100]
    private static let minimumDaysBetweenRequests: Double = 60

    static func recordEntrySubmitted() {
        entrySubmitCount += 1
    }

    static func requestReviewIfAppropriate() {
        guard milestoneCounts.contains(entrySubmitCount) else { return }

        let now = Date().timeIntervalSince1970
        let daysSinceLast = (now - lastReviewRequestDateInterval) / 86400
        guard lastReviewRequestDateInterval == 0 || daysSinceLast >= minimumDaysBetweenRequests else { return }

        lastReviewRequestDateInterval = now

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }

        SKStoreReviewController.requestReview(in: scene)
    }
}
