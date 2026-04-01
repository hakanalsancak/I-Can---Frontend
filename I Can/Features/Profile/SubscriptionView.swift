import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var isGuest = AuthService.shared.currentUser?.isGuest ?? false
    @State private var showAccountUpgrade = false

    private let features = [
        ("bubble.left.and.bubble.right.fill", "AI Coach Chat", "Ask your coach anything, anytime"),
        ("sparkles", "Daily Coach Insights", "AI coaching after every log"),
        ("chart.bar.fill", "Weekly AI Reports", "Get coaching insights every week"),
        ("chart.line.uptrend.xyaxis", "Monthly Analysis", "Deep-dive into monthly progress"),
        ("star.fill", "Yearly Review", "Comprehensive annual review"),
        ("person.2.fill", "Friends & Community", "Connect with fellow athletes"),
        ("lightbulb.fill", "Advanced Insights", "Mental patterns & trends"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    if isGuest {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text("Sign in with Apple or Google to subscribe")
                                .font(.system(size: 13, weight: .semibold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "F59E0B").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }

                    headerSection

                    VStack(spacing: 8) {
                        ForEach(features, id: \.0) { feature in
                            featureRow(icon: feature.0, title: feature.1, subtitle: feature.2)
                        }
                    }
                    .padding(.horizontal, 20)

                    trialSection

                    if let error = errorMessage {
                        Text(error)
                            .font(Typography.footnote)
                            .foregroundColor(.red)
                    }

                    VStack(spacing: 12) {
                        Button("Restore Purchases") {
                            Task { await restorePurchases() }
                        }
                        .font(Typography.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))

                        Text("Cancel anytime. No commitment.")
                            .font(Typography.footnote)
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: URL(string: "https://www.icanathlete.com/terms")!)
                            Link("Privacy Policy", destination: URL(string: "https://www.icanathlete.com/privacy")!)
                        }
                        .font(Typography.footnote)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .task { await loadProducts() }
            .sheet(isPresented: $showAccountUpgrade) {
                AccountUpgradeSheet()
            }
            .onChange(of: showAccountUpgrade) { _, isShowing in
                if !isShowing {
                    isGuest = AuthService.shared.currentUser?.isGuest ?? false
                }
            }
        }
    }

    private var trialSection: some View {
        VStack(spacing: 14) {
            Text("Choose Your Plan")
                .font(.system(size: 18, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            if isLoading {
                PrimaryButton(title: "Loading...", isLoading: true) {}
                    .padding(.horizontal, 20)
            } else if !products.isEmpty {
                VStack(spacing: 12) {
                    ForEach(products.sorted { productOrder($0) < productOrder($1) }, id: \.id) { product in
                        planButton(product: product)
                    }
                }
                .padding(.horizontal, 20)

                Text("1-month free trial included. After the trial, your subscription will automatically renew at the price shown above unless cancelled at least 24 hours before the end of the trial period.")
                    .font(.system(size: 11, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            } else {
                PrimaryButton(title: "Subscribe") {
                    Task { await retryLoadAndPurchase() }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ColorTheme.cardBackground(colorScheme))
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(hex: "EAB308").opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "EAB308").opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 32).width(.condensed))
                    .foregroundColor(Color(hex: "EAB308"))
            }
            .padding(.top, 24)

            Text("Unlock AI Coaching")
                .font(Typography.title)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text("Get personalized performance insights\npowered by AI")
                .font(Typography.subheadline)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16).width(.condensed))
                .foregroundColor(ColorTheme.accent)
                .frame(width: 36, height: 36)
                .background(ColorTheme.subtleAccent(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold).width(.condensed))
                .foregroundColor(Color(hex: "22C55E"))
        }
        .padding(14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
    }

    private var monthlyPriceText: String {
        products.first { $0.id == SubscriptionService.monthlyProductId }?.displayPrice ?? "£7.99"
    }

    private var yearlyPriceText: String {
        products.first { $0.id == SubscriptionService.yearlyProductId }?.displayPrice ?? "£59.99"
    }

    private func productOrder(_ product: Product) -> Int {
        product.id == SubscriptionService.yearlyProductId ? 0 : 1
    }

    private func planButton(product: Product) -> some View {
        let isYearly = product.id == SubscriptionService.yearlyProductId
        let hasTrial = product.subscription?.introductoryOffer != nil
        return Button {
            if isGuest {
                showAccountUpgrade = true
            } else {
                Task { await purchase(product) }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isYearly ? "\(product.displayPrice)/year" : "\(product.displayPrice)/month")
                        .font(.system(size: 18, weight: .heavy).width(.condensed))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        Text(isYearly ? "Yearly · Save 38%" : "Monthly")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(.white.opacity(0.85))
                        if hasTrial {
                            Text("· 1-month free trial")
                                .font(.system(size: 12, weight: .regular).width(.condensed))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                Spacer()
                Text(hasTrial ? "Try Free" : "Subscribe")
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isYearly ? [Color(hex: "EAB308"), Color(hex: "D97706")] : [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private func loadProducts() async {
        do {
            products = try await SubscriptionService.shared.loadProducts()
        } catch {
            errorMessage = "Could not load subscription options"
        }
        isLoading = false
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        do {
            let success = try await SubscriptionService.shared.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    private func retryLoadAndPurchase() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await SubscriptionService.shared.loadProducts()
            if products.isEmpty {
                errorMessage = "Subscription not available. Please try again later."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func restorePurchases() async {
        do {
            try await AppStore.sync()
            await SubscriptionService.shared.syncEntitlements()
            try await SubscriptionService.shared.checkStatus()
            if SubscriptionService.shared.isPremium { dismiss() }
        } catch {
            errorMessage = "Could not restore purchases"
        }
    }
}
