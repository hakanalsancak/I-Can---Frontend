import Foundation

@MainActor
@Observable
final class EntryService {
    static let shared = EntryService()

    func submitEntry(_ request: EntrySubmitRequest) async throws -> EntrySubmitResponse {
        try await APIClient.shared.request(
            APIEndpoints.Entries.base, method: "POST", body: request
        )
    }

    func getEntries(startDate: String? = nil, endDate: String? = nil, limit: Int = 30) async throws -> [DailyEntry] {
        var endpoint = APIEndpoints.Entries.base + "?limit=\(limit)"
        if let start = startDate?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&startDate=\(start)"
        }
        if let end = endDate?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "&endDate=\(end)"
        }
        let response: EntriesResponse = try await APIClient.shared.request(endpoint)
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
