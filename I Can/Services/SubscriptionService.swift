import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    var isPremium = false
    var statusChecked = false
    var subscriptionStatus: SubscriptionStatus?

    static let monthlyProductId = "com.hakanalsancak.ican.premium.monthly"
    static let yearlyProductId = "com.hakanalsancak.ican.premium.yearly"
    static let productIds: [String] = [monthlyProductId, yearlyProductId]

    func checkStatus() async throws {
        let status: SubscriptionStatus = try await APIClient.shared.request(
            APIEndpoints.Subscriptions.status
        )
        subscriptionStatus = status
        isPremium = status.isPremium
        statusChecked = true
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
            do {
                try await verifyReceipt(
                    transactionId: String(transaction.id),
                    productId: transaction.productID,
                    originalTransactionId: String(transaction.originalID),
                    jwsRepresentation: jwsRepresentation
                )
            } catch {
                await transaction.finish()
                throw error
            }
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            let jwsRepresentation = result.jwsRepresentation
            if let transaction = try? checkVerified(result) {
                do {
                    try await verifyReceipt(
                        transactionId: String(transaction.id),
                        productId: transaction.productID,
                        originalTransactionId: String(transaction.originalID),
                        jwsRepresentation: jwsRepresentation
                    )
                } catch {
                    // Backend rejected (e.g. guest account) — do not grant premium
                }
                await transaction.finish()
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
