//
//  CoreDataUserProfileDataSource.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import CoreData

class CoreDataUserProfileDataSource: BaseCoreDataProvider, UserProfileLocalDataProvider {
    // MARK: - User Profile Operations
    func saveUserProfile(_ profile: UserProfile) throws {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        let existingProfiles = try context.fetch(request)
        
        // Delete any existing profiles (we'll only store one)
        for existing in existingProfiles {
            context.delete(existing)
        }
        
        // Create new profile
        let entity = UserProfileEntity(context: context)
        entity.uid = profile.uid
        entity.email = profile.email
        entity.username = profile.username
        entity.referralCode = profile.referralCode
        entity.lastUpdated = Date()
        entity.profilePicture = profile.profilePicture
        entity.profileImageData = profile.profileImageData
        entity.backgroundImageData = profile.backgroundImageData
        
        try saveContext()
    }
    
    func getCurrentUserProfile() throws -> UserProfile? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        request.fetchLimit = 1
        
        guard let entity = try? context.fetch(request).first else {
            return nil
        }
        
        return UserProfile(
            uid: entity.uid ?? "",
            username: entity.username,
            email: entity.email,
            referralCode: entity.referralCode ?? "",
            profileImageData: entity.profileImageData,
            profilePicture: entity.profilePicture,
            backgroundImageData: entity.backgroundImageData
        )
    }
    
    func deleteUserProfile() throws {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        let profiles = try context.fetch(request)
        
        for profile in profiles {
            context.delete(profile)
        }
        
        try saveContext()
    }
    
    func updateProfileImage(_ imageData: Data) throws {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        
        guard let entity = try context.fetch(request).first else {
            throw NSError(domain: "No user found", code: 0)
        }
        
        entity.profileImageData = imageData
        try saveContext()
    }
    
    func updateBackgroundImage(_ imageData: Data?) throws {
            let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
            request.fetchLimit = 1
            
            guard let entity = try context.fetch(request).first else {
                throw NSError(domain: "No user found", code: 0)
            }
            
            entity.backgroundImageData = imageData
            try saveContext()
        }
}
