//
//  CollectiblesRepository.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//

import CoreData

class CollectiblesRepository {
    private static let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FunkoModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    private static var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - CoreData Operations
    
    private static func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - CRUD Operations
    
    static func loadItems() throws -> [Collectible] {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        let entities = try context.fetch(request)
        return entities.compactMap { $0.toCollectible() }
    }
    
    static func addItem(_ item: Collectible) throws {
        let entity = CollectibleEntity(context: context)
        entity.update(with: item)
        try saveContext()
    }
    
    static func deleteItem(for id: String) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try saveContext()
        }
    }
    
    static func clearDatabase() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = CollectibleEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
        try saveContext()
    }
    
    // MARK: - Helpers
    
    static func item(by id: String) throws -> Collectible? {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first?.toCollectible()
    }
    
    static func contains(_ item: Collectible) throws -> Bool {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id)
        let count = try context.count(for: request)
        return count > 0
    }
    
    static func updateItem(_ item: Collectible) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id)
        
        if let entity = try context.fetch(request).first {
            entity.update(with: item)
            try saveContext()
        }
    }
    
    static func updateGallery(by id: String, galleryImages: [ImageData]) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let entity = try context.fetch(request).first {
            entity.updateGallery(with: galleryImages)
            try saveContext()
        }
    }
}

// MARK: - CoreData Entity Extensions

extension CollectibleEntity {
    func update(with collectible: Collectible) {
        self.id = collectible.id
        self.inCollection = collectible.inCollection
        
        // Attributes
        self.attrName = collectible.attributes.name
        self.attrEstimatedValue = collectible.attributes._estimatedValue
        self.attrDateFrom = collectible.attributes.dateFrom
        self.attrRefNumber = collectible.attributes.refNumber
        
        // Images
        if let mainImage = collectible.attributes.images.main {
            self.mainImageUrl = mainImage.url
            self.mainImageNudity = mainImage.nudity
            self.mainImageInsensitive = mainImage.insensitive
        }
        
        if let searchImage = collectible.attributes.images.search {
            self.searchImageUrl = searchImage.url
            self.searchImageNudity = searchImage.nudity
            self.searchImageInsensitive = searchImage.insensitive
        }
        
        if let searchNoBgImage = collectible.attributes.images.searchNoBg {
            self.searchNoBgImageUrl = searchNoBgImage.url
            self.searchNoBgImageNudity = searchNoBgImage.nudity
            self.searchNoBgImageInsensitive = searchNoBgImage.insensitive
        }
        
        // Handle array-type attributes
        self.galleryImages = collectible.attributes.images.gallery.flatMap { try? JSONEncoder().encode($0) }
        self.estimatedValueRange = collectible.attributes.estimatedValueRange.flatMap { try? JSONEncoder().encode($0) }
        self.productionStatus = collectible.attributes.productionStatus.flatMap { try? JSONEncoder().encode($0) }
        self.relatedSubjects = collectible.attributes.relatedSubjects.flatMap { try? JSONEncoder().encode($0) }
    }
    
    func updateGallery(with gallery: [ImageData]) {
        self.galleryImages = try? JSONEncoder().encode(gallery)
    }
    
    func toCollectible() -> Collectible? {
        guard let id = self.id else { return nil }
        
        // Images
        var mainImage: ImageData?
        if let url = mainImageUrl {
            mainImage = ImageData(
                url: url,
                nudity: mainImageNudity,
                insensitive: mainImageInsensitive
            )
        }
        
        var searchImage: ImageData?
        if let url = searchImageUrl {
            searchImage = ImageData(
                url: url,
                nudity: searchImageNudity,
                insensitive: searchImageInsensitive
            )
        }
        
        var searchNoBgImage: ImageData?
        if let url = searchNoBgImageUrl {
            searchNoBgImage = ImageData(
                url: url,
                nudity: searchNoBgImageNudity,
                insensitive: searchNoBgImageInsensitive
            )
        }
        
        /// Decode array-type attributes
        let gallery = self.galleryImages.flatMap { try? JSONDecoder().decode([ImageData].self, from: $0) }
        let estimatedValueRange = self.estimatedValueRange.flatMap { try? JSONDecoder().decode([String?].self, from: $0) }
        let productionStatus = self.productionStatus.flatMap { try? JSONDecoder().decode([String].self, from: $0) }
        let relatedSubjects = self.relatedSubjects.flatMap { try? JSONDecoder().decode([RelatedSubject].self, from: $0) }
        
        let images = CollectibleAttributes.Images(
            main: mainImage,
            search: searchImage,
            searchNoBg: searchNoBgImage,
            gallery: gallery
        )
        
        let attributes = CollectibleAttributes(
            images: images,
            name: attrName ?? "",
            _estimatedValue: attrEstimatedValue,
            estimatedValueRange: estimatedValueRange,
            relatedSubjects: relatedSubjects,
            dateFrom: attrDateFrom,
            productionStatus: productionStatus,
            refNumber: attrRefNumber
        )
        
        return Collectible(
            id: id,
            attributes: attributes,
            inCollection: inCollection
        )
    }
}
