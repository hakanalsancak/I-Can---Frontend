import Foundation

enum APIEndpoints {
    #if DEBUG
    static let baseURL = "https://i-can-backend-development.onrender.com"
    #else
    static let baseURL = "https://i-can-backend.onrender.com"
    #endif

    enum Auth {
        static let register = "/api/auth/register"
        static let apple = "/api/auth/apple"
        static let google = "/api/auth/google"
        static let refresh = "/api/auth/refresh"
        static let onboarding = "/api/auth/onboarding"
        static let profile = "/api/auth/profile"
        static let logout = "/api/auth/logout"
        static let linkApple = "/api/auth/link-apple"
        static let linkGoogle = "/api/auth/link-google"
        static let deleteAccount = "/api/auth/account"
        static let profilePhoto = "/api/auth/profile/photo"
    }

    enum Entries {
        static let base = "/api/entries"
        static let insight = "/api/entries/insight"
        static let analytics = "/api/entries/analytics"
        static func byDate(_ date: String) -> String { "/api/entries/\(date)" }
    }

    enum Friends {
        static let base = "/api/friends"
        static let search = "/api/friends/search"
        static let checkUsername = "/api/friends/check-username"
        static let requests = "/api/friends/requests"
        static let sendRequest = "/api/friends/request"
        static func respondRequest(_ id: String) -> String { "/api/friends/request/\(id)" }
        static func cancelRequest(_ id: String) -> String { "/api/friends/request/\(id)" }
        static func profile(_ id: String) -> String { "/api/friends/profile/\(id)" }
        static func remove(_ id: String) -> String { "/api/friends/\(id)" }
    }

    enum Reports {
        static let base = "/api/reports"
        static let status = "/api/reports/status"
        static func byId(_ id: String) -> String { "/api/reports/\(id)" }
    }

    enum Chat {
        static let base = "/api/chat"
        static let conversations = "/api/chat/conversations"
        static func conversationMessages(_ id: String) -> String { "/api/chat/conversations/\(id)/messages" }
        static func renameConversation(_ id: String) -> String { "/api/chat/conversations/\(id)/title" }
        static func togglePin(_ id: String) -> String { "/api/chat/conversations/\(id)/pin" }
        static func deleteConversation(_ id: String) -> String { "/api/chat/conversations/\(id)" }
    }

    enum JournalNotes {
        static let base = "/api/journal-notes"
        static func byDate(_ date: String) -> String { "/api/journal-notes/\(date)" }
    }

    enum Feedback {
        static let base = "/api/feedback"
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

    enum App {
        static let version = "/api/app/version"
    }

}
