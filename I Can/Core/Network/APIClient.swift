import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
    }

    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = TokenManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401, authenticated {
            do {
                try await refreshAccessToken()
                if let newToken = TokenManager.shared.accessToken {
                    var retryRequest = urlRequest
                    retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await performRequest(retryRequest)
                    guard let retryHttp = retryResponse as? HTTPURLResponse,
                          (200...299).contains(retryHttp.statusCode) else {
                        throw APIError.unauthorized
                    }
                    return try decoder.decode(T.self, from: retryData)
                }
            } catch {
                throw APIError.unauthorized
            }
            throw APIError.unauthorized
        }

        if httpResponse.statusCode == 403 {
            let errorBody = try? decoder.decode(APIErrorResponse.self, from: data)
            if errorBody?.code == "PREMIUM_REQUIRED" {
                throw APIError.premiumRequired
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorBody?.error ?? "Server error (\(httpResponse.statusCode))")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = TokenManager.shared.refreshToken else {
            throw APIError.unauthorized
        }

        struct RefreshBody: Encodable { let refreshToken: String }
        struct TokenResponse: Decodable { let accessToken: String; let refreshToken: String }

        let body = RefreshBody(refreshToken: refreshToken)
        let tokenResponse: TokenResponse = try await request(
            APIEndpoints.Auth.refresh,
            method: "POST",
            body: body,
            authenticated: false
        )
        TokenManager.shared.saveTokens(access: tokenResponse.accessToken, refresh: tokenResponse.refreshToken)
    }
}

private struct APIErrorResponse: Decodable {
    let error: String
    let code: String?
}

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
