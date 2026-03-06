import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService.shared
    @State private var showOnboarding = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "")
            } else if !authService.isAuthenticated {
                OnboardingView()
            } else if !authService.hasCompletedOnboarding {
                OnboardingView(startAtStep: .sportSelection)
            } else {
                MainTabView()
            }
        }
        .task {
            await loadInitialState()
        }
    }

    private func loadInitialState() async {
        if authService.isAuthenticated {
            do {
                try await authService.loadProfile()
            } catch {
                authService.signOut()
            }
        }
        isLoading = false
    }
}
