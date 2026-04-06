import FirebaseAnalytics

enum AnalyticsManager {
    static func log(_ event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }

    static func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    /// Call after subscription status is checked to keep user properties in sync
    static func updateSubscriptionProperties(status: SubscriptionStatus) {
        // "free", "trial", "monthly", "yearly"
        let tier: String
        if !status.isPremium {
            tier = "free"
        } else if status.status == "trial" {
            tier = "trial"
        } else if status.productId == SubscriptionService.yearlyProductId {
            tier = "yearly"
        } else {
            tier = "monthly"
        }
        setUserProperty(tier, forName: "subscription_tier")
        setUserProperty(status.isPremium ? "premium" : "free", forName: "subscription_status")
    }
}
