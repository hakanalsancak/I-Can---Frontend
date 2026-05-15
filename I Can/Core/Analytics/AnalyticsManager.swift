import FirebaseAnalytics

enum AnalyticsManager {
    static func log(_ event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }

    static func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}
