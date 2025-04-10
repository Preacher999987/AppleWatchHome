//
//  ProfileInfoViewModel.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import Foundation
import GoogleSignIn

class ProfileInfoViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository: UserProfileRepositoryProtocol
    
    init(repository: UserProfileRepositoryProtocol = UserProfileRepository()) {
        self.repository = repository
        loadUserProfile()
    }
    
    // TODO: Add Production URLs from Info.plist
    var appShareURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "AppShareURL") as? String,
              let url = URL(string: urlString) else {
            return URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")! // Fallback URL
        }
        return url
    }
    
    var contactUsURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "ContactUsURL") as? String,
              let url = URL(string: urlString) else {
            return URL(string: "https://instagram.com/funkollector")! // Fallback URL
        }
        return url
    }
    
    func updateProfileImage(_ imageData: Data) async throws {
        await MainActor.run {
            isLoading = true
            do {
                try repository.updateProfileImage(imageData)
                userProfile = try repository.getCurrentUserProfile()
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func loadUserProfile() {
        isLoading = true
        do {
            userProfile = try repository.getCurrentUserProfile()
            error = nil
        } catch {
            self.error = error
            userProfile = nil
        }
        isLoading = false
    }
    
    func logout() {
        KeychainHelper.logout()
        // Additional cleanup if needed
        GIDSignIn.sharedInstance.signOut()
        try? repository.deleteUserProfile()
    }
}
