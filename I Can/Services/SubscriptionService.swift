import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    var isPremium = false
    var statusChecked = false
    var subscriptionStatus: SubscriptionStatus?

    static let monthlyProductId = "com.ican.premium.monthly"
    static let yearlyProductId = "com.ican.premium.yearly"
    static let productIds: [String] = [monthlyProductId, yearlyProductId]

    func checkStatus() async throws {
        defer { statusChecked = true }
        let status: SubscriptionStatus = try await APIClient.shared.request(
            APIEndpoints.Subscriptions.status
        )
        subscriptionStatus = status
        isPremium = status.isPremium
    }

    func verifyReceipt(transactionId: String, productId: String, originalTransactionId: String?, jwsRepresentation: String) async throws {
        let request = VerifyReceiptRequest(
            transactionId: transactionId,
            productId: productId,
            originalTransactionId: originalTransactionId,
            jwsRepresentation: jwsRepresentation
        )
        let status: SubscriptionStatus = try await APIClient.shared.request(
            APIEndpoints.Subscriptions.verify, method: "POST", body: request
        )
        subscriptionStatus = status
        isPremium = status.isPremium
    }

    func loadProducts() async throws -> [Product] {
        try await Product.products(for: Self.productIds)
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let jwsRepresentation = verification.jwsRepresentation
            let transaction = try checkVerified(verification)

            // Reject revoked transactions immediately
            if transaction.revocationDate != nil {
                await transaction.finish()
                throw APIError.serverError("This transaction has been revoked")
            }

            try await verifyReceipt(
                transactionId: String(transaction.id),
                productId: transaction.productID,
                originalTransactionId: String(transaction.originalID),
                jwsRepresentation: jwsRepresentation
            )

            // Re-verify with backend to ensure the subscription is truly active
            try await checkStatus()
            if isPremium {
                await transaction.finish()
                return true
            } else {
                // Backend says not premium despite receipt verification — don't grant access
                await transaction.finish()
                return false
            }
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Iterates Apple's current entitlements and verifies any active subscriptions
    /// with the backend. Skips revoked or expired transactions.
    func syncEntitlements() async {
        for await result in Transaction.currentEntitlements {
            let jwsRepresentation = result.jwsRepresentation
            if let transaction = try? checkVerified(result) {
                // Skip revoked transactions
                if transaction.revocationDate != nil {
                    await transaction.finish()
                    continue
                }
                // Skip expired subscriptions
                if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                    await transaction.finish()
                    continue
                }
                do {
                    try await verifyReceipt(
                        transactionId: String(transaction.id),
                        productId: transaction.productID,
                        originalTransactionId: String(transaction.originalID),
                        jwsRepresentation: jwsRepresentation
                    )
                } catch {
                    // Will retry on next launch
                }
                await transaction.finish()
            }
        }
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            let jwsRepresentation = result.jwsRepresentation
            if let transaction = try? checkVerified(result) {
                // Skip revoked transactions — payment may have failed
                if transaction.revocationDate != nil {
                    await transaction.finish()
                    // Revocation means premium should be removed — re-check with backend
                    try? await checkStatus()
                    continue
                }
                // Skip expired subscriptions
                if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                    await transaction.finish()
                    try? await checkStatus()
                    continue
                }
                do {
                    try await verifyReceipt(
                        transactionId: String(transaction.id),
                        productId: transaction.productID,
                        originalTransactionId: String(transaction.originalID),
                        jwsRepresentation: jwsRepresentation
                    )
                    await transaction.finish()
                } catch {
                    // Don't finish — StoreKit will redeliver on next launch
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw APIError.serverError("Transaction verification failed")
        case .verified(let safe): return safe
        }
    }

    func resetForSignOut() {
        isPremium = false
        statusChecked = false
        subscriptionStatus = nil
    }

    private init() {}
}
