import Foundation

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
        if let start = startDate { endpoint += "&startDate=\(start)" }
        if let end = endDate { endpoint += "&endDate=\(end)" }
        let response: EntriesResponse = try await APIClient.shared.request(endpoint)
        return response.entries
    }

    func getEntry(date: String) async throws -> DailyEntry {
        try await APIClient.shared.request(APIEndpoints.Entries.byDate(date))
    }

    private init() {}
}
