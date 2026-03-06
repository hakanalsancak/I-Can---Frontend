import Foundation
import StoreKit

@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    var isPremium = false
    var subscriptionStatus: SubscriptionStatus?

    static let productId = "com.hakanalsancak.ican.premium.monthly"

    func checkStatus() async throws {
        let status: SubscriptionStatus = try await APIClient.shared.request(
            APIEndpoints.Subscriptions.status
        )
        subscriptionStatus = status
        isPremium = status.isPremium
    }

    func verifyReceipt(transactionId: String, productId: String, originalTransactionId: String?) async throws {
        let request = VerifyReceiptRequest(
            transactionId: transactionId,
            productId: productId,
            originalTransactionId: originalTransactionId
        )
        let status: SubscriptionStatus = try await APIClient.shared.request(
            APIEndpoints.Subscriptions.verify, method: "POST", body: request
        )
        subscriptionStatus = status
        isPremium = status.isPremium
    }

    func loadProducts() async throws -> [Product] {
        try await Product.products(for: [Self.productId])
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            try await verifyReceipt(
                transactionId: String(transaction.id),
                productId: transaction.productID,
                originalTransactionId: String(transaction.originalID)
            )
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
            if let transaction = try? checkVerified(result) {
                try? await verifyReceipt(
                    transactionId: String(transaction.id),
                    productId: transaction.productID,
                    originalTransactionId: String(transaction.originalID)
                )
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

    private init() {}
}
