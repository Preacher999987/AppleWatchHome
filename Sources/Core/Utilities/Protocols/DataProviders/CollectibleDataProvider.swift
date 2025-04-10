//
//  CollectibleDataProvider.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

protocol CollectibleLocalDataProvider {
    
    // MARK: - CRUD
    func fetchCollectibles() throws -> [Collectible]
    
    func item(by id: String) throws -> Collectible?
    
    func addItems(_ items: [Collectible]) throws
    
    func deleteItem(for id: String) throws
    
    func updateItem(_ item: Collectible) throws
    
    func updateGallery(by id: String, galleryImages: [ImageData]) throws
    
    // MARK: - Helpers
    
    func contains(_ item: Collectible) throws -> Bool
    func clearDatabase() throws
}

protocol CollectibleRemoteDataProvider {
    func fetchCollectibles(for id: String) async throws -> [Collectible]
}

protocol CollectibleRepositoryProtocol {
    func getCollectibles() async throws -> [Collectible]
    
    func refreshCollectibles() async throws -> [Collectible]
    
    func addItems(_ items: [Collectible]) throws
    
    func deleteItem(for id: String) throws
    
    func clearDatabase() throws
    // MARK: - Helpers
    
    func item(by id: String) throws -> Collectible?
    
    func contains(_ item: Collectible) throws -> Bool
    
    func updateItem(_ item: Collectible) throws
    
    func updateGallery(by id: String, galleryImages: [ImageData]) throws
}
