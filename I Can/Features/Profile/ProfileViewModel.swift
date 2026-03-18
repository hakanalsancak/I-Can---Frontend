import Foundation
import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ProfileViewModel {
    var user: User? { AuthService.shared.currentUser }
    var streak: StreakInfo?
    var subscriptionStatus: SubscriptionStatus?
    var isLoading = false
    var showSubscription = false
    var showSettings = false
    var showMantraEditor = false
    var showEditProfile = false
    var profileImage: UIImage?
    var isSavingProfile = false

    var isPremium: Bool { SubscriptionService.shared.isPremium }

    func loadData() async {
        isLoading = true
        async let streakTask: () = loadStreak()
        async let subTask: () = loadSubscription()
        async let photoTask: () = loadProfilePhotoAsync()
        _ = await (streakTask, subTask, photoTask)
        isLoading = false
    }

    private func loadStreak() async {
        do {
            streak = try await StreakService.shared.getStreak()
        } catch { }
    }

    private func loadSubscription() async {
        do {
            try await SubscriptionService.shared.checkStatus()
            subscriptionStatus = SubscriptionService.shared.subscriptionStatus
        } catch { }
    }

    func saveMantra(_ mantra: String) async -> Bool {
        do {
            try await AuthService.shared.updateMantra(mantra)
            HapticManager.notification(.success)
            return true
        } catch {
            HapticManager.notification(.error)
            return false
        }
    }

    func saveProfile(
        fullName: String,
        username: String,
        sport: String,
        team: String,
        position: String,
        mantra: String,
        photo: UIImage?,
        removePhoto: Bool = false
    ) async -> Bool {
        isSavingProfile = true
        defer { isSavingProfile = false }
        do {
            let currentUser = AuthService.shared.currentUser
            let nameToSend = fullName != (currentUser?.fullName ?? "") ? fullName : nil
            let usernameToSend = username != (currentUser?.username ?? "") ? username : nil
            let sportToSend = sport != (currentUser?.sport ?? "") ? sport : nil
            let teamToSend = team != (currentUser?.team ?? "") ? team : nil
            let positionToSend = position != (currentUser?.position ?? "") ? position : nil
            let mantraToSend = mantra != (currentUser?.mantra ?? "") ? mantra : nil

            try await AuthService.shared.updateProfile(
                fullName: nameToSend,
                username: usernameToSend,
                sport: sportToSend,
                team: teamToSend,
                position: positionToSend,
                mantra: mantraToSend
            )

            if removePhoto {
                let _: [String: String]? = try? await APIClient.shared.request(
                    APIEndpoints.Auth.profilePhoto, method: "DELETE"
                )
                deleteProfilePhoto()
                profileImage = nil
            } else if let photo {
                saveProfilePhoto(photo)
                profileImage = photo
                if let data = photo.jpegData(compressionQuality: 0.8) {
                    if let updatedUser: User = try? await APIClient.shared.uploadImage(
                        APIEndpoints.Auth.profilePhoto,
                        imageData: data
                    ) {
                        AuthService.shared.currentUser = updatedUser
                    }
                }
            }

            HapticManager.notification(.success)
            return true
        } catch {
            HapticManager.notification(.error)
            return false
        }
    }

    // MARK: - Local Photo Storage

    func loadProfilePhoto() {
        guard let userId = user?.id,
              let url = Self.photoURL(for: userId),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        profileImage = image
    }

    private func loadProfilePhotoAsync() async {
        // Try local cache first
        if let userId = user?.id,
           let localURL = Self.photoURL(for: userId) {
            let image = await Task.detached(priority: .userInitiated) {
                guard let data = try? Data(contentsOf: localURL) else { return nil as UIImage? }
                return UIImage(data: data)
            }.value
            if let image {
                profileImage = image
                return
            }
        }

        // Fall back to server URL (e.g. new device, reinstall)
        if let photoUrlString = user?.profilePhotoUrl,
           let serverURL = URL(string: photoUrlString) {
            let image = await Task.detached(priority: .userInitiated) {
                guard let data = try? Data(contentsOf: serverURL) else { return nil as UIImage? }
                return UIImage(data: data)
            }.value
            if let image {
                profileImage = image
                saveProfilePhoto(image)
            }
        }
    }

    func saveProfilePhoto(_ image: UIImage) {
        guard let userId = user?.id,
              let url = Self.photoURL(for: userId),
              let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: url, options: .completeFileProtection)
    }

    func deleteProfilePhoto() {
        guard let userId = user?.id,
              let url = Self.photoURL(for: userId) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private static func photoURL(for userId: String) -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return dir.appendingPathComponent("profile_photo_\(userId).jpg")
    }

    func signOut() {
        AuthService.shared.signOut()
    }
}
