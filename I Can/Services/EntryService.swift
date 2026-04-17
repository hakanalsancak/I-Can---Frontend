import Foundation

@MainActor
@Observable
final class EntryService {
    static let shared = EntryService()

    private var cachedEntries: [DailyEntry] = []
    private var entriesFetchedAt: Date?
    private let cacheMaxAge: TimeInterval = 60

    func getEntries(startDate: String? = nil, endDate: String? = nil, limit: Int = 30, forceRefresh: Bool = false) async throws -> [DailyEntry] {
        // Return cached data for default (no date filter) requests within cache window
        if !forceRefresh, startDate == nil, endDate == nil, limit == 30,
           let fetchedAt = entriesFetchedAt, Date().timeIntervalSince(fetchedAt) < cacheMaxAge,
           !cachedEntries.isEmpty {
            return cachedEntries
        }

        var endpoint = APIEndpoints.Entries.base + "?limit=\(limit)"
        if let start = startDate?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&startDate=\(start)"
        }
        if let end = endDate?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&endDate=\(end)"
        }
        let response: EntriesResponse = try await APIClient.shared.request(endpoint)

        // Cache only default requests
        if startDate == nil, endDate == nil, limit == 30 {
            cachedEntries = response.entries
            entriesFetchedAt = Date()
        }

        return response.entries
    }

    func getEntry(date: String) async throws -> DailyEntry {
        try await APIClient.shared.request(APIEndpoints.Entries.byDate(date))
    }

    func generateInsight(_ request: InsightRequest) async throws -> String {
        let response: InsightResponse = try await APIClient.shared.request(
            APIEndpoints.Entries.insight, method: "POST", body: request
        )
        return response.insight
    }

    private init() {}
}
