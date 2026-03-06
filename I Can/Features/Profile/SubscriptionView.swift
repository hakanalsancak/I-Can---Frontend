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
        ("chart.line.uptrend.xyaxis", "Monthly Analysis", "Deep-dive into your monthly progress"),
        ("star.fill", "Yearly Review", "Comprehensive annual performance review"),
        ("target", "Goal Coaching", "AI feedback tied to your personal goals"),
        ("lightbulb.fill", "Advanced Insights", "Mental patterns & performance trends"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    VStack(spacing: 12) {
                        ForEach(features, id: \.0) { feature in
                            featureRow(icon: feature.0, title: feature.1, subtitle: feature.2)
                        }
                    }
                    .padding(.horizontal, 20)

                    if let product = products.first {
                        VStack(spacing: 8) {
                            Text("1 Month Free Trial")
                                .font(Typography.headline)
                                .foregroundColor(ColorTheme.primaryText(colorScheme))

                            Text("Then \(product.displayPrice)/month")
                                .font(Typography.subheadline)
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))

                            PrimaryButton(
                                title: "Start Free Trial",
                                isLoading: isPurchasing
                            ) {
                                Task { await purchase(product) }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else if isLoading {
                        ProgressView()
                            .padding()
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(Typography.footnote)
                            .foregroundColor(.red)
                    }

                    Button("Restore Purchases") {
                        Task { await restorePurchases() }
                    }
                    .font(Typography.footnote)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))

                    Text("Cancel anytime. No commitment.")
                        .font(Typography.caption)
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .padding(.bottom, 40)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(ColorTheme.accent)
                }
            }
            .task { await loadProducts() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
                .padding(.top, 24)

            Text("Unlock AI Coaching")
                .font(Typography.title)
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Text("Get personalized performance insights\npowered by AI")
                .font(Typography.body)
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ColorTheme.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }

            Spacer()

            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
        .padding(16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
