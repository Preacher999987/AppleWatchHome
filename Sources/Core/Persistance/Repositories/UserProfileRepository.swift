//
//  UserProfileRepository.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import CoreData

class UserProfileRepository: UserProfileRepositoryProtocol {
    private let localDataSource: UserProfileLocalDataProvider
    
    init(localDataSource: UserProfileLocalDataProvider = CoreDataUserProfileDataSource()) {
        self.localDataSource = localDataSource
    }
    
    // MARK: - User Profile Operations
    func saveUserProfile(_ profile: UserProfile) throws {
        try localDataSource.saveUserProfile(profile)
    }
    
    func getCurrentUserProfile() throws -> UserProfile? {
        try localDataSource.getCurrentUserProfile()
    }
    
    func deleteUserProfile() throws {
        try localDataSource.deleteUserProfile()
    }
    
    func updateProfileImage(_ imageData: Data) throws {
        try localDataSource.updateProfileImage(imageData)
    }
}
