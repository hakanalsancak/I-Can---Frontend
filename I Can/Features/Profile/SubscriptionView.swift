import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let features = [
        ("chart.bar.fill", "Weekly AI Reports", "Get coaching insights every week"),
        ("chart.line.uptrend.xyaxis", "Monthly Analysis", "Deep-dive into monthly progress"),
        ("star.fill", "Yearly Review", "Comprehensive annual review"),
        ("target", "Goal Coaching", "AI feedback tied to your goals"),
        ("lightbulb.fill", "Advanced Insights", "Mental patterns & trends"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
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
        }
    }

    private var trialSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "EAB308"))
                Text("1 MONTH FREE TRIAL")
                    .font(.system(size: 14, weight: .heavy).width(.condensed))
                    .foregroundColor(Color(hex: "EAB308"))
            }

            if let product = products.first {
                Text("Then \(product.displayPrice)/month")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            } else if !isLoading {
                Text("$9.99/month after trial")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            if isLoading {
                PrimaryButton(title: "Loading...", isLoading: true) {}
                    .padding(.horizontal, 20)
            } else if let product = products.first {
                PrimaryButton(
                    title: "Start Free Trial",
                    isLoading: isPurchasing
                ) {
                    Task { await purchase(product) }
                }
                .padding(.horizontal, 20)
            } else {
                PrimaryButton(title: "Start Free Trial") {
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
        isPurchasing = true
        do {
            products = try await SubscriptionService.shared.loadProducts()
            if let product = products.first {
                let success = try await SubscriptionService.shared.purchase(product)
                if success { dismiss() }
            } else {
                errorMessage = "Subscription not available. Please try again later."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    private func restorePurchases() async {
        do {
            try await AppStore.sync()
            try await SubscriptionService.shared.checkStatus()
            if SubscriptionService.shared.isPremium { dismiss() }
        } catch {
            errorMessage = "Could not restore purchases"
        }
    }
}
