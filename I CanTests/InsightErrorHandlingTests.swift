import Testing
import Foundation
@testable import I_Can

/// C-7: fetchInsight must surface errors via insightFailed flag
/// instead of silently swallowing them in an empty catch block.
struct InsightErrorHandlingTests {

    @Test("insightFailed starts as false")
    @MainActor
    func initialState() {
        let vm = DailyEntryViewModel()
        #expect(vm.insightFailed == false)
        #expect(vm.coachInsight == "")
        #expect(vm.isLoadingInsight == false)
    }

    @Test("insightFailed is true after fetchInsight fails")
    @MainActor
    func insightFailedSetOnError() async {
        // fetchInsight calls EntryService.shared.generateInsight which hits the network.
        // Without a running backend, this will throw, which is what we want to test.
        // We also need isPremium to be true for fetchInsight to proceed.
        let originalPremium = SubscriptionService.shared.isPremium
        SubscriptionService.shared.isPremium = true

        let vm = DailyEntryViewModel()
        vm.activityType = "training"

        await vm.fetchInsight()

        // The network call should fail (no backend running in tests),
        // so insightFailed must be true
        #expect(vm.insightFailed == true, "insightFailed should be set when API call fails")
        #expect(vm.isLoadingInsight == false, "Loading should be reset after failure")

        // Restore
        SubscriptionService.shared.isPremium = originalPremium
    }

    @Test("fetchInsight is skipped for non-premium users")
    @MainActor
    func skippedForFreeUsers() async {
        let originalPremium = SubscriptionService.shared.isPremium
        SubscriptionService.shared.isPremium = false

        let vm = DailyEntryViewModel()
        vm.activityType = "training"

        await vm.fetchInsight()

        // Should exit early without setting any state
        #expect(vm.insightFailed == false)
        #expect(vm.coachInsight == "")
        #expect(vm.isLoadingInsight == false)

        // Restore
        SubscriptionService.shared.isPremium = originalPremium
    }

    @Test("coachInsight remains empty when fetch fails")
    @MainActor
    func insightEmptyOnFailure() async {
        let originalPremium = SubscriptionService.shared.isPremium
        SubscriptionService.shared.isPremium = true

        let vm = DailyEntryViewModel()
        vm.activityType = "game"

        await vm.fetchInsight()

        #expect(vm.coachInsight == "", "coachInsight should remain empty on failure")
        #expect(vm.insightFailed == true)

        // Restore
        SubscriptionService.shared.isPremium = originalPremium
    }
}
