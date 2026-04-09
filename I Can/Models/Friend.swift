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
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let senderId: String
    let createdAt: String?
    let sender: AthleteProfile
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
