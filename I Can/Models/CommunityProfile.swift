import Foundation

struct CommunityProfile: Codable, Identifiable, Hashable {
    let id: String
    let handle: String?
    let fullName: String?
    let bio: String?
    let sport: String?
    let position: String?
    let country: String?
    let profilePhotoUrl: String?
    let profileVisibility: String
    let isSelf: Bool
    let stats: CommunityProfileStats
    var relation: CommunityProfileRelation

    var displayName: String {
        if let name = fullName, !name.isEmpty { return name }
        if let h = handle, !h.isEmpty { return "@\(h)" }
        return "Athlete"
    }
}

struct CommunityProfileStats: Codable, Hashable {
    let currentStreak: Int
    let longestStreak: Int
    let totalSessions: Int
    let postCount: Int
    let followerCount: Int
    let followingCount: Int
}

struct CommunityProfileRelation: Codable, Hashable {
    var isFriend: Bool
    var isFollowing: Bool
    var isFollowedBy: Bool
    var isBlocked: Bool
}
