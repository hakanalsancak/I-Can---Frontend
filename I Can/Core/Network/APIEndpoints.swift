import Foundation

enum APIEndpoints {
    #if DEBUG
    static let baseURL = "http://localhost:3000"
    #else
    static let baseURL = "https://your-app.onrender.com"
    #endif

    enum Auth {
        static let register = "/api/auth/register"
        static let login = "/api/auth/login"
        static let apple = "/api/auth/apple"
        static let google = "/api/auth/google"
        static let refresh = "/api/auth/refresh"
        static let onboarding = "/api/auth/onboarding"
        static let profile = "/api/auth/profile"
    }

    enum Entries {
        static let base = "/api/entries"
        static func byDate(_ date: String) -> String { "/api/entries/\(date)" }
    }

    enum Goals {
        static let base = "/api/goals"
        static func byId(_ id: String) -> String { "/api/goals/\(id)" }
    }

    enum Reports {
        static let base = "/api/reports"
        static let generate = "/api/reports/generate"
        static let canGenerate = "/api/reports/can-generate"
        static func byId(_ id: String) -> String { "/api/reports/\(id)" }
    }

    enum Streaks {
        static let base = "/api/streaks"
    }

    enum Subscriptions {
        static let status = "/api/subscriptions/status"
        static let verify = "/api/subscriptions/verify"
    }

    enum Notifications {
        static let preferences = "/api/notifications/preferences"
        static let deviceToken = "/api/notifications/device-token"
    }
}
