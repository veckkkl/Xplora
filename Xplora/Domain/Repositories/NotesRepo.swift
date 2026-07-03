//
//  NotesRepo.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

enum NoteRepositoryError: Error {
    case notFound
    case persistenceFailure
}

protocol NotesRepo {
    func fetchAllNotes() async throws -> [Note]
    func getNote(id: String) async throws -> Note
    func save(note: Note) async throws -> Note
    func delete(noteId: String) async throws
    func deleteAll() async throws
}
