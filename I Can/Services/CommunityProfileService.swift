import Foundation

@MainActor
@Observable
final class CommunityProfileService {
    static let shared = CommunityProfileService()

    private(set) var myProfile: CommunityProfile?
    private(set) var profileCache: [String: CommunityProfile] = [:]

    private init() {}

    func loadMyProfile() async throws -> CommunityProfile {
        let p: CommunityProfile = try await APIClient.shared.request(
            APIEndpoints.Community.myProfile
        )
        myProfile = p
        return p
    }

    func loadProfile(userId: String) async throws -> CommunityProfile {
        let p: CommunityProfile = try await APIClient.shared.request(
            APIEndpoints.Community.userProfile(userId)
        )
        profileCache[userId] = p
        return p
    }

    @discardableResult
    func follow(userId: String) async throws -> Bool {
        struct Resp: Decodable { let following: Bool }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.follow(userId),
            method: "POST"
        )
        updateRelation(userId: userId) { $0.isFollowing = r.following }
        return r.following
    }

    @discardableResult
    func unfollow(userId: String) async throws -> Bool {
        struct Resp: Decodable { let following: Bool }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.follow(userId),
            method: "DELETE"
        )
        updateRelation(userId: userId) { $0.isFollowing = r.following }
        return r.following
    }

    func setHandle(_ handle: String) async throws -> String {
        struct Body: Encodable { let handle: String }
        struct Resp: Decodable { let handle: String }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.myHandle,
            method: "PUT",
            body: Body(handle: handle)
        )
        if let existing = myProfile {
            myProfile = CommunityProfile(
                id: existing.id,
                handle: r.handle,
                fullName: existing.fullName,
                bio: existing.bio,
                sport: existing.sport,
                position: existing.position,
                country: existing.country,
                profilePhotoUrl: existing.profilePhotoUrl,
                profileVisibility: existing.profileVisibility,
                isSelf: existing.isSelf,
                stats: existing.stats,
                relation: existing.relation
            )
        }
        return r.handle
    }

    func setBio(_ bio: String?) async throws -> String? {
        struct Body: Encodable { let bio: String? }
        struct Resp: Decodable { let bio: String? }
        let r: Resp = try await APIClient.shared.request(
            APIEndpoints.Community.myBio,
            method: "PUT",
            body: Body(bio: bio)
        )
        if let existing = myProfile {
            myProfile = CommunityProfile(
                id: existing.id,
                handle: existing.handle,
                fullName: existing.fullName,
                bio: r.bio,
                sport: existing.sport,
                position: existing.position,
                country: existing.country,
                profilePhotoUrl: existing.profilePhotoUrl,
                profileVisibility: existing.profileVisibility,
                isSelf: existing.isSelf,
                stats: existing.stats,
                relation: existing.relation
            )
        }
        return r.bio
    }

    private func updateRelation(userId: String, mutate: (inout CommunityProfileRelation) -> Void) {
        if var cached = profileCache[userId] {
            mutate(&cached.relation)
            profileCache[userId] = cached
        }
        if var me = myProfile, me.id == userId {
            mutate(&me.relation)
            myProfile = me
        }
    }
}
