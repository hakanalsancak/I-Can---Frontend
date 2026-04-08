import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case tokenExpired
    case premiumRequired
    case dailyLimitExceeded(resetAt: Date?)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)

    /// Network or server errors that should NOT force a sign-out when they
    /// occur during token refresh — the server may just be temporarily down.
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError: return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Please sign in again"
        case .tokenExpired: return "Session expired"
        case .premiumRequired: return "Premium subscription required"
        case .dailyLimitExceeded: return "Daily message limit reached"
        case .serverError(let msg): return msg
        case .networkError(let error): return error.localizedDescription
        case .decodingError: return "Failed to process server response"
        }
    }
}
