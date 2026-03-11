import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService.shared
    @State private var isLoading = true
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Group {
                if !authService.isAuthenticated {
                    OnboardingView()
                } else if !authService.hasCompletedOnboarding {
                    OnboardingView(startAtStep: .sportSelection)
                } else {
                    MainTabView()
                }
            }
            .opacity(isLoading ? 0 : 1)

            if isLoading {
                splashScreen
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isLoading)
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
                try? await SubscriptionService.shared.checkStatus()
            } catch {
                authService.signOut()
            }
        }

        try? await Task.sleep(nanoseconds: 300_000_000)

        isLoading = false
    }
}
