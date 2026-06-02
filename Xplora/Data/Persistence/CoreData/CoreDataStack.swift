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

        // NSPersistentContainer auto-creates a description with the correct
        // URL (Application Support/<bundle>/<modelName>.sqlite) so the store
        // survives app restarts. Replacing it with a blank
        // NSPersistentStoreDescription() drops that URL — the store ends up
        // in an undefined location and notes disappear between launches.
        // Mutate the existing description in place instead.
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            if inMemory {
                description.type = NSInMemoryStoreType
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

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
