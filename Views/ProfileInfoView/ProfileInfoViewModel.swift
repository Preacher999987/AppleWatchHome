//
//  ProfileInfoViewModel.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import Foundation

class ProfileInfoViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        loadUserProfile()
    }
    
    func loadUserProfile() {
        isLoading = true
        do {
            userProfile = try UserProfileRepository.getCurrentUserProfile()
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
    }
}

// Protocol for testability
protocol UserProfileRepositoryProtocol {
    static func getCurrentUserProfile() throws -> UserProfile?
}

// Make the actual repository conform to the protocol
extension UserProfileRepository: UserProfileRepositoryProtocol {}
