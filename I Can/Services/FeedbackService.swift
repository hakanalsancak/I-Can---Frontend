import Foundation

enum FeedbackService {
    struct FeedbackRequest: Encodable {
        let message: String
        let email: String?
    }

    struct FeedbackResponse: Decodable {
        let success: Bool
    }

    static func submit(message: String, email: String?) async throws {
        let _: FeedbackResponse = try await APIClient.shared.request(
            APIEndpoints.Feedback.base,
            method: "POST",
            body: FeedbackRequest(message: message, email: email?.isEmpty == true ? nil : email)
        )
    }
}
