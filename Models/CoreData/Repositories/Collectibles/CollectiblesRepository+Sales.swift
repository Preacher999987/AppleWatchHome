//
//  CollectiblesRepository+Sales.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import CoreData

extension CollectiblesRepository {
    static func updateSaleInfo(for id: String, soldPrice: Float?, soldDate: Date?, platform: String?) throws {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let entity = try context.fetch(request).first {
            entity.soldPrice = soldPrice ?? 0
            entity.soldDate = soldDate
            entity.soldPlatform = platform
            try saveContext()
        }
    }
    
    static func markAsSold(for id: String, soldPrice: Float, soldDate: Date, platform: String) throws {
        try updateSaleInfo(for: id, soldPrice: soldPrice, soldDate: soldDate, platform: platform)
    }
    
    static func markAsUnsold(for id: String) throws {
        try updateSaleInfo(for: id, soldPrice: nil, soldDate: nil, platform: nil)
    }
    
    static func getSoldItems() throws -> [Collectible] {
        let request: NSFetchRequest<CollectibleEntity> = CollectibleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "soldPrice > 0")
        let entities = try context.fetch(request)
        return entities.compactMap { $0.toCollectible() }
    }
}
