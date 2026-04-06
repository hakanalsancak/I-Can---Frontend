import Foundation

struct JournalNote: Codable {
    let noteDate: String
    let content: String
    let updatedAt: String?
}

struct JournalNoteUpsertRequest: Encodable {
    let content: String
}

@MainActor
@Observable
final class JournalNoteService {
    static let shared = JournalNoteService()

    func getNote(date: String) async throws -> JournalNote {
        try await APIClient.shared.request(
            APIEndpoints.JournalNotes.byDate(date)
        )
    }

    func getNotes(start: String, end: String) async throws -> [JournalNote] {
        try await APIClient.shared.request(
            APIEndpoints.JournalNotes.base + "?start=\(start)&end=\(end)"
        )
    }

    func saveNote(date: String, content: String) async throws -> JournalNote {
        try await APIClient.shared.request(
            APIEndpoints.JournalNotes.byDate(date),
            method: "PUT",
            body: JournalNoteUpsertRequest(content: content)
        )
    }

    private init() {}
}
