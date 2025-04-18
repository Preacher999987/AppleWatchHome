//
//  UserProfileDataProvider.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

protocol UserProfileLocalDataProvider {
    // MARK: - User Profile Operations
    func saveUserProfile(_ profile: UserProfile) throws
    
    func getCurrentUserProfile() throws -> UserProfile?
    
    func deleteUserProfile() throws
    
    func updateProfileImage(_ imageData: Data) throws
    
    func updateBackgroundImage(_ imageData: Data?) throws
}

protocol UserProfileRepositoryProtocol {
    
    // MARK: - User Profile Operations
    func saveUserProfile(_ profile: UserProfile) throws
    
    func getCurrentUserProfile() throws -> UserProfile?
    
    func deleteUserProfile() throws
    
    func updateProfileImage(_ imageData: Data) throws
    
    func updateBackgroundImage(_ imageData: Data?) throws
}
