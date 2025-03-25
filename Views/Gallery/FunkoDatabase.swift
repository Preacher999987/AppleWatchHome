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
    
    // Save items to database
    static func saveItems(_ items: [AnalysisResult]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // Load items from database
    static func loadItems() throws -> [AnalysisResult] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [] // Return empty array if file doesn't exist yet
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([AnalysisResult].self, from: data)
    }
    
    // Add single item
    static func addItem(_ item: AnalysisResult) throws {
        var currentItems = (try? loadItems()) ?? []
        currentItems.append(item)
        try saveItems(currentItems)
    }
    
    // Delete item by index
    static func deleteItem(at index: Int) throws {
        var currentItems = try loadItems()
        guard index < currentItems.count else { return }
        currentItems.remove(at: index)
        try saveItems(currentItems)
    }
    
    // Clear all items
    static func clearDatabase() throws {
        try saveItems([])
    }
}
