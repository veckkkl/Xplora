//
//  CoreDataStack.swift
//  Xplora
//

import CoreData
import Foundation

final class CoreDataStack {
    static let modelName = "XploraDataModel"

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: Self.modelName)
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if inMemory {
            description.type = NSInMemoryStoreType
        }
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load persistent stores: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
}
