import Foundation
import CryptoKit

// MARK: - Certificate Pinning Delegate

private final class PinningDelegate: NSObject, URLSessionDelegate, Sendable {
    // SHA-256 fingerprint of the server's leaf certificate (base64-encoded).
    // Update this when you rotate your TLS certificate.
    // To obtain: openssl s_client -connect i-can-backend.onrender.com:443 </dev/null 2>/dev/null \
    //   | openssl x509 -noout -pubkey | openssl pkey -pubin -outform der \
    //   | openssl dgst -sha256 -binary | base64
    //
    // TODO: Run the command above and paste the result here before shipping to production.
    // While this is nil, the app relies on default system TLS validation only.
    private static let pinnedPublicKeyHash: String? = nil

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // If no pin is configured, fall back to default system validation (still enforces HTTPS)
        guard let expectedHash = Self.pinnedPublicKeyHash else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate trust first
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract the leaf certificate's public key and hash it
        guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let certificate = chain.first,
              let publicKey = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let hash = SHA256.hash(data: publicKeyData)
        let hashBase64 = Data(hash).base64EncodedString()

        if hashBase64 == expectedHash {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Token Refresh Coordinator

/// Ensures only one token refresh happens at a time across concurrent requests.
private actor TokenRefreshCoordinator {
    private var activeRefresh: Task<Void, Error>?

    func refresh(using refreshAction: @escaping @Sendable () async throws -> Void) async throws {
        // If a refresh is already in progress, wait for it instead of starting another
        if let existing = activeRefresh {
            try await existing.value
            return
        }

        let task = Task { try await refreshAction() }
        activeRefresh = task

        do {
            try await task.value
            activeRefresh = nil
        } catch {
            activeRefresh = nil
            throw error
        }
    }
}

// MARK: - API Client

final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let refreshCoordinator = TokenRefreshCoordinator()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
#if DEBUG
        session = URLSession(configuration: config)
#else
        session = URLSession(configuration: config, delegate: PinningDelegate(), delegateQueue: nil)
#endif
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
                try await refreshCoordinator.refresh { [self] in
                    try await self.refreshAccessToken()
                }
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

        if httpResponse.statusCode == 429 {
            let errorBody = try? decoder.decode(APIErrorResponse.self, from: data)
            if errorBody?.code == "DAILY_LIMIT_EXCEEDED" {
                let resetDate = errorBody?.resetAt.flatMap { ISO8601DateFormatter().date(from: $0) }
                throw APIError.dailyLimitExceeded(resetAt: resetDate)
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

    func uploadImage<T: Decodable>(
        _ endpoint: String,
        imageData: Data,
        fieldName: String = "photo",
        fileName: String = "photo.jpg"
    ) async throws -> T {
        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n--\(boundary)--\r\n")

        urlRequest.httpBody = body

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            do {
                try await refreshCoordinator.refresh { [self] in
                    try await self.refreshAccessToken()
                }
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

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorBody?.error ?? "Server error (\(httpResponse.statusCode))")
        }

        return try decoder.decode(T.self, from: data)
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
    let resetAt: String?
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
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
