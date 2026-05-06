import Foundation

struct AthleteProfile: Codable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let sport: String?
    let team: String?
    let position: String?
    let country: String?
    let competitionLevel: String?
    let mantra: String?
    let profilePhotoUrl: String?
    let currentStreak: Int
    let longestStreak: Int?
    var friendStatus: String?
    var isFriend: Bool?
    let height: Double?
    let weight: Double?
    let logsHidden: Bool?
}

struct FriendDailyLog: Codable, Identifiable {
    let id: String
    let entryDate: String
    let completedSections: [String]
    let training: FriendTrainingData?
    let nutrition: FriendNutrition?
    let sleep: FriendSleep?

    var date: Date? { Date.fromAPIString(entryDate) }

    var hasTraining: Bool { completedSections.contains("training") }
    var hasNutrition: Bool { completedSections.contains("nutrition") }
    var hasSleep: Bool { completedSections.contains("sleep") }
}

struct FriendTrainingData: Codable {
    let sessions: [FriendTrainingSession]

    var totalDuration: Int {
        sessions.reduce(0) { $0 + ($1.duration ?? 0) }
    }
}

struct FriendTrainingSession: Codable {
    let trainingType: String?
    let duration: Int?
    let intensity: String?
    let sessionScore: Int?

    var trainingTypeDisplay: String {
        switch trainingType {
        case "match": return "Match"
        case "gym": return "Gym"
        case "cardio": return "Cardio"
        case "technical": return "Technical"
        case "tactical": return "Tactical"
        case "recovery": return "Recovery"
        case "other": return "Other"
        case .some(let raw) where !raw.isEmpty: return raw.capitalized
        default: return "Training"
        }
    }
}

struct FriendNutrition: Codable {
    let breakfast: String?
    let lunch: String?
    let dinner: String?
    let snacks: String?
    let drinks: String?
    let healthScore: Int?
}

struct FriendSleep: Codable {
    let sleepTime: String?
    let wakeTime: String?

    var durationHours: Double? {
        guard let s = sleepTime, let w = wakeTime else { return nil }
        let sp = s.split(separator: ":").compactMap { Int($0) }
        let wp = w.split(separator: ":").compactMap { Int($0) }
        guard sp.count >= 1, wp.count >= 1 else { return nil }
        let sm = sp[0] * 60 + (sp.count > 1 ? sp[1] : 0)
        let wm = wp[0] * 60 + (wp.count > 1 ? wp[1] : 0)
        var diff = wm - sm
        if diff < 0 { diff += 24 * 60 }
        return Double(diff) / 60.0
    }
}

struct FriendDailyLogsResponse: Codable {
    let logs: [FriendDailyLog]
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let senderId: String
    let createdAt: String?
    let sender: AthleteProfile
}

struct SentFriendRequest: Codable, Identifiable {
    let id: String
    let receiverId: String
    let createdAt: String?
    let receiver: AthleteProfile
}

struct FriendActionResponse: Codable {
    let success: Bool
    let action: String?
}

struct SendFriendRequestResponse: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let status: String
    let createdAt: String?
}

struct UsernameCheck: Codable {
    let available: Bool
    let error: String?
}
