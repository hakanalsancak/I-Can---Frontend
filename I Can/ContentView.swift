import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService.shared
    @State private var isLoading = true
    @State private var showMaintenance = false
    @State private var showPostOnboardingSubscription = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme

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

            if showMaintenance {
                ServerMaintenanceView(onRetry: { await retryConnection() })
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showingSplash)
        .animation(.easeInOut(duration: 0.3), value: showMaintenance)
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
        } catch {
            if case .unauthorized = error as? APIError {
                authService.signOut()
                showMaintenance = false
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

    private func loadInitialState() async {
        if authService.isAuthenticated {
            do {
                try await authService.loadProfile()
                await authService.setCountryIfNeeded()
                try? await SubscriptionService.shared.checkStatus()
                showMaintenance = false
            } catch {
                if case .unauthorized = error as? APIError {
                    authService.signOut()
                } else {
                    showMaintenance = true
                }
            }
        }

        try? await Task.sleep(nanoseconds: 300_000_000)

        isLoading = false
    }
}
