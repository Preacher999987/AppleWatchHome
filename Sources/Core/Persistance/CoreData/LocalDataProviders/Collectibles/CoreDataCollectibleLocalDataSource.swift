//
//  CoreDataCollectibleLocalDataSource.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import CoreData


class CoreDataCollectibleLocalDataSource: BaseCoreDataProvider, CollectibleLocalDataProvider {
   
    // MARK: - CRUD Operations
    
    func fetchCollectibles() throws -> [Collectible] {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        let entities = try context.fetch(request)
        return entities.compactMap { $0.toCollectible() }
    }
    
    func addItems(_ items: [Collectible]) throws {
        // Fetch all existing entities first
        let existingIds = try fetchCollectibles().map { $0.id }
        
        // Add only the items that are not already present
        items.forEach {
            guard !existingIds.contains($0.id) else { return }
            
            let entity = CollectibleEntity(context: context)
            entity.update(with: $0)
        }
        
        // Save all changes in a single operation
        try saveContext()
    }
    
    func deleteItem(for id: String) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try saveContext()
        }
    }
    
    func clearDatabase() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = CollectibleEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
        try saveContext()
    }
    
    // MARK: - Helpers
    
    func item(by id: String) throws -> Collectible? {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first?.toCollectible()
    }
    
    func contains(_ item: Collectible) throws -> Bool {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id)
        let count = try context.count(for: request)
        return count > 0
    }
    
    func updateItem(_ item: Collectible) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id)
        
        if let entity = try context.fetch(request).first {
            entity.update(with: item)
            try saveContext()
        }
    }
    
    func updateGallery(by id: String, galleryImages: [ImageData]) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let entity = try context.fetch(request).first {
            entity.updateGallery(with: galleryImages)
            try saveContext()
        }
    }
}
