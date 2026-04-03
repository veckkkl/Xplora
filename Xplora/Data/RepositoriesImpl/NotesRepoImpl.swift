//
//  NotesRepoImpl.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import CoreData
import Foundation

final class NotesRepoImpl: NotesRepo {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func fetchAllNotes() async throws -> [Note] {
        try await performInViewContext { context in
            let request = CDNote.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: #keyPath(CDNote.updatedAt), ascending: false),
                NSSortDescriptor(key: #keyPath(CDNote.createdAt), ascending: false)
            ]
            let notes = try context.fetch(request)
            return notes.map(NoteCoreDataMapper.toDomain)
        }
    }

    func getNote(id: String) async throws -> Note {
        try await performInViewContext { context in
            guard let managedNote = try self.fetchManagedNote(id: id, in: context) else {
                throw NoteRepositoryError.notFound
            }
            return NoteCoreDataMapper.toDomain(managedNote)
        }
    }

    func save(note: Note) async throws -> Note {
        try await performInViewContext { context in
            let managedNote = try self.fetchManagedNote(id: note.id, in: context) ?? CDNote(context: context)
            NoteCoreDataMapper.upsert(note, into: managedNote, in: context)

            if context.hasChanges {
                try context.save()
            }

            return NoteCoreDataMapper.toDomain(managedNote)
        }
    }

    func delete(noteId: String) async throws {
        try await performInViewContext { context in
            guard let managedNote = try self.fetchManagedNote(id: noteId, in: context) else {
                throw NoteRepositoryError.notFound
            }

            context.delete(managedNote)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func fetchManagedNote(id: String, in context: NSManagedObjectContext) throws -> CDNote? {
        let request = CDNote.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first
    }

    private func performInViewContext<T>(
        _ work: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = coreDataStack.viewContext

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let value = try work(context)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
