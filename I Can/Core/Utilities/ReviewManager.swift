import StoreKit
import SwiftUI
import UIKit

enum ReviewManager {
    @AppStorage("hasRequestedReview") private static var hasRequestedReview: Bool = false

    static func requestReviewAfterFirstLog() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }

        SKStoreReviewController.requestReview(in: scene)
    }
}
