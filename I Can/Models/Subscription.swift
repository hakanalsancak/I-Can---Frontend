import Foundation

struct SubscriptionStatus: Codable {
    let status: String
    let isPremium: Bool
    let trialEnd: String?
    let currentPeriodEnd: String?
    let productId: String?
}

struct VerifyReceiptRequest: Encodable {
    let transactionId: String
    let productId: String
    let originalTransactionId: String?
}
