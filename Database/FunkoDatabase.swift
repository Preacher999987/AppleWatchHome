//
//  FunkoDatabase.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//


import Foundation

class FunkoDatabase {
    private static let fileName = "funko_collection.json"
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    // MARK: - CRUD Operations
    
    // Save items to database
    static func saveItems(_ items: [Collectible]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // Load items from database
    static func loadItems() throws -> [Collectible] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Collectible].self, from: data)
    }
    
    // Add single item
    static func addItem(_ item: Collectible) throws {
        var currentItems = try loadItems()
        currentItems.append(item)
        try saveItems(currentItems)
    }
    
    // Delete item by object reference (new method)
    static func deleteItem(for id: String) throws {
        var currentItems = try loadItems()
        currentItems.removeAll { $0.id == id }
        try saveItems(currentItems)
    }
    
    // Clear all items
    static func clearDatabase() throws {
        try saveItems([])
    }
    
    // MARK: - Helpers
    
    // Return item by id
    static func item(by id: String) throws -> Collectible? {
        let currentItems = try loadItems()
        return currentItems.first { $0.id == id}
    }
    
    // Check if item exists in collection
    static func contains(_ item: Collectible) throws -> Bool {
        let currentItems = try loadItems()
        return currentItems.contains { $0.id == item.id }
    }
    
    // Update an existing item
    static func updateItem(_ item: Collectible) throws {
        var currentItems = try loadItems()
        if let index = currentItems.firstIndex(where: { $0.id == item.id }) {
            currentItems[index] = item
            try saveItems(currentItems)
        }
    }
    
    // Update gallery images
    static func updateGallery(by id: String, galleryImages: [ImageData]) throws {
        if var item = try? item(by: id) {
            item.attributes.images.gallery = galleryImages
            try updateItem(item)
        }
    }
}
