import FirebaseAnalytics

enum AnalyticsManager {
    static func log(_ event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }
}
