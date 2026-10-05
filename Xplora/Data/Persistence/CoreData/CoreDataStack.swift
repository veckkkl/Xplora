//
//  CoreDataStack.swift
//  Xplora
//

import CoreData
import Foundation
import os

enum CoreDataStackError: Error {
    /// The persistent store failed to load. The on-disk store is left untouched;
    /// no context is handed out so nothing reads from or writes to it.
    case persistentStoreUnavailable(underlying: Error)
}

final class CoreDataStack {
    static let modelName = "XploraDataModel"

    /// Loaded once so several stacks (e.g. in tests) share one model and
    /// entity → class mapping stays unambiguous.
    private static let model: NSManagedObjectModel = {
        guard
            let url = Bundle(for: CoreDataStack.self).url(forResource: modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: url)
        else {
            fatalError("Missing Core Data model \(modelName)")
        }
        return model
    }()

    let container: NSPersistentContainer

    /// Set when `loadPersistentStores` reports a failure.
    var loadError: Error? {
        lock.withLock { _loadError }
    }

    private var _loadError: Error?
    private let lock = NSLock()

    init(inMemory: Bool = false, storeURL: URL? = nil) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: Self.model)

        // NSPersistentContainer auto-creates a description with the correct
        // URL (Application Support/<bundle>/<modelName>.sqlite) so the store
        // survives app restarts. Replacing it with a blank
        // NSPersistentStoreDescription() drops that URL — the store ends up
        // in an undefined location and notes disappear between launches.
        // Mutate the existing description in place instead.
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            // Loading must finish inside init so `loadError` is final afterwards.
            description.shouldAddStoreAsynchronously = false
            if let storeURL {
                description.url = storeURL
            }
            if inMemory {
                description.type = NSInMemoryStoreType
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        _loadError = Self.loadStores(into: container)

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var isStoreLoaded: Bool {
        loadError == nil
    }

    /// The main context, available only when the persistent store loaded.
    ///
    /// After a failed load, each call retries adding the store once (a failed
    /// store is never attached to the coordinator, so adding it again is safe).
    /// This makes a user-triggered Retry real for transient failures; the
    /// on-disk store is never deleted or migrated destructively.
    /// Throws `CoreDataStackError.persistentStoreUnavailable` while it still fails.
    func loadedViewContext() throws -> NSManagedObjectContext {
        try lock.withLock {
            if _loadError != nil {
                _loadError = Self.loadStores(into: container)
            }
            if let loadError = _loadError {
                throw CoreDataStackError.persistentStoreUnavailable(underlying: loadError)
            }
        }
        return container.viewContext
    }

    private static func loadStores(into container: NSPersistentContainer) -> Error? {
        var loadError: Error?
        container.loadPersistentStores { description, error in
            guard let error else { return }
            loadError = error
            let nsError = error as NSError
            Logger.storage.fault(
                "Core Data store load failed type=\(description.type, privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
        }
        return loadError
    }
}
