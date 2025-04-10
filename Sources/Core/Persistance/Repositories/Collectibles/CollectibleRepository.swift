//
//  CollectibleRepository.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//

import CoreData

class CollectibleRepository: CollectibleRepositoryProtocol {
    private let localDataSource: CollectibleLocalDataProvider
    private let remoteDataSource: CollectibleRemoteDataProvider
    
    private let userRepository: UserProfileRepositoryProtocol
    
    init(localDataSource: CollectibleLocalDataProvider = CoreDataCollectibleLocalDataSource(),
         remoteDataSource: CollectibleRemoteDataProvider = CollectibleNetworkDataProvider(),
         userRepository: UserProfileRepositoryProtocol = UserProfileRepository()) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.userRepository = userRepository
    }
    
    // MARK: - CRUD Operations
    
    func getCollectibles() async throws -> [Collectible] {
        // First try local storage
        let localItems = try localDataSource.fetchCollectibles()
        
        if localItems.isEmpty {
            guard let uid = try userRepository.getCurrentUserProfile()?.uid else {
                throw AuthError.userNotAuthenticated
            }
            
            // Fallback to remote if local is empty
            let remoteItems = try await remoteDataSource.fetchCollectibles(for: uid)
            try localDataSource.addItems(remoteItems)
            
            return remoteItems
        }
        
        return localItems
    }
    
    func refreshCollectibles() async throws -> [Collectible] {
        // TODO: -
        //            let remoteItems = try await remoteDataSource.refreshCollectibles()
        //            try localDataSource.clearDatabase()
        //            try localDataSource.saveItems(remoteItems)
        //            return remoteItems
        return []
    }
    
    func addItems(_ items: [Collectible]) throws {
        try localDataSource.addItems(items)
    }
    
    func deleteItem(for id: String) throws {
        try localDataSource.deleteItem(for: id)
    }
    
    func clearDatabase() throws {
        try localDataSource.clearDatabase()
    }
    
    // MARK: - Helpers
    
    func item(by id: String) throws -> Collectible? {
        try localDataSource.item(by: id)
    }
    
    func contains(_ item: Collectible) throws -> Bool {
        try localDataSource.contains(item)
    }
    
    func updateItem(_ item: Collectible) throws {
        try localDataSource.updateItem(item)
    }
    
    func updateGallery(by id: String, galleryImages: [ImageData]) throws {
        try localDataSource.updateGallery(by: id, galleryImages: galleryImages)
    }
}
