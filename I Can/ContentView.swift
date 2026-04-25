import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService.shared
    @State private var isLoading = true
    @State private var showMaintenance = false
    @State private var showNoInternet = false
    @State private var showForceUpdate = false
    @State private var showAppMaintenance = false
    @State private var latestMinVersion: String?
    @State private var currentAppVersion: String?
    @State private var showPostOnboardingSubscription = false
    @State private var activeFeedbackCampaign: String?
    @State private var showFeedbackCampaign = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    private static let feedbackCampaignSeenKey = "lastSeenFeedbackCampaign"

    private var showingSplash: Bool {
        isLoading || (authService.isAuthenticated && authService.hasCompletedOnboarding && !SubscriptionService.shared.statusChecked)
    }

    var body: some View {
        ZStack {
            Group {
                if !authService.isAuthenticated {
                    OnboardingView()
                } else if !authService.hasCompletedOnboarding {
                    OnboardingView(startAtStep: .sportSelection)
                } else {
                    MainTabView()
                        .fullScreenCover(isPresented: $showPostOnboardingSubscription) {
                            SubscriptionView()
                        }
                }
            }
            .opacity(showingSplash ? 0 : 1)

            if showingSplash {
                splashScreen
                    .transition(.opacity)
            }

            if showForceUpdate {
                ForceUpdateView(
                    currentVersion: currentAppVersion,
                    minVersion: latestMinVersion
                )
                .transition(.opacity)
                .zIndex(12)
            }

            if showAppMaintenance {
                AppMaintenanceView(onRetry: { await retryAppMaintenance() })
                    .transition(.opacity)
                    .zIndex(11)
            }

            if showNoInternet {
                NoInternetView(onRetry: { await retryConnection() })
                    .transition(.opacity)
                    .zIndex(10)
            }

            if showMaintenance {
                ServerMaintenanceView(onRetry: { await retryConnection() })
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .sheet(isPresented: $showFeedbackCampaign) {
            if let campaign = activeFeedbackCampaign {
                FeedbackCampaignSheet(campaign: campaign) {
                    UserDefaults.standard.set(campaign, forKey: Self.feedbackCampaignSeenKey)
                    activeFeedbackCampaign = nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showingSplash)
        .animation(.easeInOut(duration: 0.3), value: showNoInternet)
        .animation(.easeInOut(duration: 0.3), value: showMaintenance)
        .animation(.easeInOut(duration: 0.3), value: showForceUpdate)
        .animation(.easeInOut(duration: 0.3), value: showAppMaintenance)
        .task {
            await loadInitialState()
        }
        .onChange(of: authService.isAuthenticated) { _, newValue in
            if newValue {
                Task {
                    try? await SubscriptionService.shared.checkStatus()
                }
            }
        }
        .onChange(of: authService.hasCompletedOnboarding) { _, newValue in
            if newValue && authService.justCompletedOnboarding {
                authService.justCompletedOnboarding = false
                if !SubscriptionService.shared.isPremium {
                    showPostOnboardingSubscription = true
                }
            }
        }
    }

    private func retryConnection() async {
        do {
            try await authService.loadProfile()
            try? await SubscriptionService.shared.checkStatus()
            showMaintenance = false
            showNoInternet = false
        } catch {
            if case .unauthorized = error as? APIError {
                authService.signOut()
                showMaintenance = false
                showNoInternet = false
            } else if case .networkError = error as? APIError {
                showNoInternet = true
                showMaintenance = false
            } else {
                showMaintenance = true
                showNoInternet = false
            }
        }
    }

    private var splashScreen: some View {
        ZStack {
            ColorTheme.background(colorScheme)
                .ignoresSafeArea()

            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.5)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                }
        }
    }

    private func checkForceUpdate() async {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        let endpoint = "\(APIEndpoints.App.version)?current=\(currentVersion)"
        struct VersionResponse: Decodable {
            let minVersion: String
            let forceUpdate: Bool
            let maintenance: Bool?
            let feedbackCampaign: String?
        }
        do {
            let response: VersionResponse = try await APIClient.shared.request(endpoint, authenticated: false)
            currentAppVersion = currentVersion
            latestMinVersion = response.minVersion
            showForceUpdate = response.forceUpdate
            showAppMaintenance = !response.forceUpdate && (response.maintenance ?? false)
            activeFeedbackCampaign = response.feedbackCampaign
        } catch {
            // Don't block the app if version check fails
        }
    }

    private func presentFeedbackCampaignIfNeeded() {
        guard let campaign = activeFeedbackCampaign,
              !campaign.isEmpty,
              authService.isAuthenticated,
              authService.hasCompletedOnboarding,
              !showForceUpdate,
              !showAppMaintenance,
              !showMaintenance,
              !showNoInternet,
              !showPostOnboardingSubscription
        else { return }

        let lastSeen = UserDefaults.standard.string(forKey: Self.feedbackCampaignSeenKey)
        guard lastSeen != campaign else { return }

        showFeedbackCampaign = true
    }

    private func loadInitialState() async {
        await checkForceUpdate()
        if showForceUpdate { return }
        if showAppMaintenance {
            isLoading = false
            return
        }

        await hydrateAuthenticatedSession()

        try? await Task.sleep(nanoseconds: 300_000_000)

        isLoading = false

        try? await Task.sleep(nanoseconds: 600_000_000)
        presentFeedbackCampaignIfNeeded()
    }

    private func hydrateAuthenticatedSession() async {
        guard authService.isAuthenticated else { return }
        do {
            try await authService.loadProfile()
            await authService.setCountryIfNeeded()
            try? await SubscriptionService.shared.checkStatus()
            showMaintenance = false
            showNoInternet = false
        } catch {
            if case .unauthorized = error as? APIError {
                authService.signOut()
            } else if case .networkError = error as? APIError {
                showNoInternet = true
            } else {
                showMaintenance = true
            }
        }
    }

    private func retryAppMaintenance() async {
        await checkForceUpdate()
        if showForceUpdate || showAppMaintenance { return }
        await hydrateAuthenticatedSession()
    }
}
