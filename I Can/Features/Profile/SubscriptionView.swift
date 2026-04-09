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
    @State private var selectedProduct: Product?
    @State private var trialEligibility: [String: Bool] = [:]
    @State private var appearAnimation = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerPhase: CGFloat = -1

    private var userName: String {
        AuthService.shared.currentUser?.fullName?.components(separatedBy: " ").first ?? "Athlete"
    }

    private var userSport: String {
        AuthService.shared.currentUser?.sport.capitalized ?? "Sport"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if isGuest {
                        guestBanner
                    }

                    heroSection
                        .padding(.bottom, 28)

                    // CTA first — above fold
                    planSection
                        .padding(.bottom, 32)

                    socialProofSection
                        .padding(.bottom, 28)

                    benefitsGrid
                        .padding(.bottom, 28)

                    comparisonSection
                        .padding(.bottom, 28)

                    guaranteeSection
                        .padding(.bottom, 20)

                    footerSection
                        .padding(.bottom, 40)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
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
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    appearAnimation = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.06
                }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    shimmerPhase = 2
                }
            }
        }
    }

    // MARK: - Guest Banner

    private var guestBanner: some View {
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
        .padding(.top, 8)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "EAB308").opacity(0.2), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EAB308"), Color(hex: "F59E0B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "EAB308").opacity(0.4), radius: 16, x: 0, y: 8)

                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
            }
            .padding(.top, 24)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)

            VStack(spacing: 8) {
                Text("\(userName), Train Smarter")
                    .font(Typography.title)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text("Your AI \(userSport) coach analyzes every entry\nand gives you personalized insights to improve")
                    .font(Typography.subheadline)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 10)
        }
    }

    // MARK: - Plan Section

    private var planSection: some View {
        VStack(spacing: 16) {
            if isLoading {
                PrimaryButton(title: "Loading...", isLoading: true) {}
                    .padding(.horizontal, 20)
            } else if !products.isEmpty {
                VStack(spacing: 10) {
                    ForEach(products.sorted { productOrder($0) < productOrder($1) }, id: \.id) { product in
                        planCard(product: product)
                    }
                }
                .padding(.horizontal, 20)

                // Main CTA
                Button {
                    if isGuest {
                        showAccountUpgrade = true
                    } else if let product = selectedProduct ?? products.sorted(by: { productOrder($0) < productOrder($1) }).first {
                        Task { await purchase(product) }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "EAB308"), Color(hex: "D97706")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(hex: "EAB308").opacity(0.4), radius: 16, x: 0, y: 8)

                        // Shimmer overlay
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0), .white.opacity(0.2), .white.opacity(0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.4)
                                .offset(x: shimmerPhase * geo.size.width)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        HStack(spacing: 8) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .bold))
                                Text(ctaButtonText)
                                    .font(.system(size: 18, weight: .heavy).width(.condensed))
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .frame(height: 56)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isPurchasing)
                .padding(.horizontal, 20)

                if anyProductHasTrial {
                    Text("7-day free trial included. After the trial, your subscription will automatically renew at the price shown above unless cancelled at least 24 hours before the end of the trial period.")
                        .font(.system(size: 11, weight: .regular).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else {
                    Text("Your subscription will automatically renew at the price shown above unless cancelled at least 24 hours before the end of the current period.")
                        .font(.system(size: 11, weight: .regular).width(.condensed))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else {
                PrimaryButton(title: "Subscribe") {
                    Task { await retryLoadAndPurchase() }
                }
                .padding(.horizontal, 20)
            }

            if let error = errorMessage {
                Text(error)
                    .font(Typography.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
        }
    }

    private var ctaButtonText: String {
        let product = selectedProduct ?? products.sorted(by: { productOrder($0) < productOrder($1) }).first
        guard let product else { return "Get Premium Now" }
        return isTrialEligible(product) ? "Start Free Trial" : "Get Premium Now"
    }

    private func planCard(product: Product) -> some View {
        let isYearly = product.id == SubscriptionService.yearlyProductId
        let hasTrial = isTrialEligible(product)
        let isSelected = (selectedProduct?.id ?? products.sorted(by: { productOrder($0) < productOrder($1) }).first?.id) == product.id

        return Button {
            HapticManager.selection()
            selectedProduct = product
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color(hex: "EAB308") : ColorTheme.tertiaryText(colorScheme),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "EAB308"))
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.system(size: 17, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                        if isYearly {
                            Text("SAVE 38%")
                                .font(.system(size: 10, weight: .heavy).width(.condensed))
                                .foregroundColor(Color(hex: "EAB308"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "EAB308").opacity(0.12))
                                .clipShape(Capsule())
                        }
                        if isYearly {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .heavy).width(.condensed))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "22C55E"))
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 4) {
                        if hasTrial {
                            Text("7-day free trial, then")
                                .font(.system(size: 13, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        Text(isYearly ? "\(product.displayPrice)/year" : "\(product.displayPrice)/month")
                            .font(.system(size: 13, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color(hex: "EAB308") : ColorTheme.separator(colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? Color(hex: "EAB308").opacity(0.15) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Social Proof

    private var socialProofSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "EAB308"))
                }
                Text("4.9")
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }

            Text("\"I improved my focus score by 40% in just 3 weeks.\nThe AI coach spotted patterns I never noticed.\"")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .italic()

            Text("-- Premium Athlete")
                .font(.system(size: 13, weight: .medium).width(.condensed))
                .foregroundColor(ColorTheme.tertiaryText(colorScheme))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    // MARK: - Benefits Grid

    private var benefitsGrid: some View {
        VStack(spacing: 12) {
            Text("EVERYTHING IN PREMIUM")
                .sectionHeader(colorScheme)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                benefitTile(icon: "brain.head.profile", title: "AI Coach", subtitle: "Unlimited chats", gradient: ["0EA5E9", "22C55E"])
                benefitTile(icon: "sparkles", title: "Daily Insights", subtitle: "After every log", gradient: ["EAB308", "F59E0B"])
                benefitTile(icon: "chart.bar.fill", title: "Weekly Reports", subtitle: "Pattern analysis", gradient: ["8B5CF6", "6D28D9"])
                benefitTile(icon: "chart.line.uptrend.xyaxis", title: "Monthly Reviews", subtitle: "Deep-dive coaching", gradient: ["2563EB", "1D4ED8"])
                benefitTile(icon: "star.fill", title: "Yearly Analysis", subtitle: "Track your growth", gradient: ["F59E0B", "D97706"])
                benefitTile(icon: "target", title: "Goal Coaching", subtitle: "Personalized plans", gradient: ["22C55E", "16A34A"])
            }
            .padding(.horizontal, 20)
        }
    }

    private func benefitTile(icon: String, title: String, subtitle: String, gradient: [String]) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    // MARK: - Comparison

    private var comparisonSection: some View {
        VStack(spacing: 14) {
            Text("FREE VS PREMIUM")
                .sectionHeader(colorScheme)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                comparisonHeader
                comparisonRow("Daily Logging", free: true, premium: true, isLast: false)
                comparisonRow("Streaks & Journal", free: true, premium: true, isLast: false)
                comparisonRow("Breathing Exercise", free: true, premium: true, isLast: false)
                comparisonRow("AI Coach Chat", free: "15/day", premium: "Unlimited", isLast: false)
                comparisonRow("Daily AI Insights", free: false, premium: true, isLast: false)
                comparisonRow("Weekly Reports", free: false, premium: true, isLast: false)
                comparisonRow("Monthly Deep Dives", free: false, premium: true, isLast: false)
                comparisonRow("Yearly Analysis", free: false, premium: true, isLast: false)
                comparisonRow("Mental Pattern Analysis", free: false, premium: true, isLast: true)
            }
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    private var comparisonHeader: some View {
        HStack {
            Text("Feature")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Free")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .frame(width: 60)
            Text("Premium")
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .foregroundColor(Color(hex: "EAB308"))
                .frame(width: 70)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ColorTheme.elevatedBackground(colorScheme))
    }

    private func comparisonRow(_ feature: String, free: Any, premium: Any, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                comparisonCell(value: free)
                    .frame(width: 60)

                comparisonCell(value: premium)
                    .frame(width: 70)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            if !isLast {
                Rectangle()
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }

    @ViewBuilder
    private func comparisonCell(value: Any) -> some View {
        if let bool = value as? Bool {
            if bool {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "22C55E"))
            } else {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
        } else if let text = value as? String {
            Text(text)
                .font(.system(size: 11, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
    }

    // MARK: - Guarantee

    private var guaranteeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color(hex: "22C55E"))

            VStack(alignment: .leading, spacing: 2) {
                Text("Cancel Anytime")
                    .font(.system(size: 15, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("No commitment, no hidden fees. Manage your subscription in Settings anytime.")
                    .font(.system(size: 13, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "22C55E").opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: "22C55E").opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await restorePurchases() }
            }
            .font(Typography.subheadline)
            .foregroundColor(ColorTheme.secondaryText(colorScheme))

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://www.icanathlete.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://www.icanathlete.com/privacy")!)
            }
            .font(Typography.footnote)
            .foregroundColor(ColorTheme.secondaryText(colorScheme))
        }
    }

    // MARK: - Helpers

    private var anyProductHasTrial: Bool {
        products.contains { trialEligibility[$0.id] == true }
    }

    private func isTrialEligible(_ product: Product) -> Bool {
        trialEligibility[product.id] == true
    }

    private func productOrder(_ product: Product) -> Int {
        product.id == SubscriptionService.yearlyProductId ? 0 : 1
    }

    private func loadProducts() async {
        do {
            products = try await SubscriptionService.shared.loadProducts()
            for product in products {
                if let subscription = product.subscription {
                    let eligible = await subscription.isEligibleForIntroOffer
                    trialEligibility[product.id] = eligible
                }
            }
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

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
