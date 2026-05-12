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
    let jwsRepresentation: String
}

struct ClaimCodeRequest: Encodable {
    let code: String
}

struct ClaimCodeResponse: Decodable {
    let ok: Bool
    let code: String
    let influencerName: String?
    let discountPercent: Int
}
