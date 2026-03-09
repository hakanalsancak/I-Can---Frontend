import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { userId }
    let rank: Int
    let userId: String
    let fullName: String
    let sport: String
    let country: String?
    let currentStreak: Int
    let longestStreak: Int
    let isMe: Bool
}

struct LeaderboardResponse: Codable {
    let leaderboard: [LeaderboardEntry]
    let myRank: Int?
    let myStreak: Int
    let countryCode: String?
}
