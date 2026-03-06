import Foundation

struct StreakInfo: Codable {
    let currentStreak: Int
    let longestStreak: Int
    var lastEntryDate: String?
}
