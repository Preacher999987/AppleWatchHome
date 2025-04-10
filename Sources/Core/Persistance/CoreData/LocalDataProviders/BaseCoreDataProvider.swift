//
//  BaseCoreDataProvider.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import CoreData

class BaseCoreDataProvider {
    private let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FunkoModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - CoreData Operations
    
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
