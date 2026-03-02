//
//  NotesRepo.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

enum NoteRepositoryError: Error {
    case notFound
}

protocol NotesRepo {
    func getNote(id: String) async throws -> Note
    func save(note: Note) async throws -> Note
    func delete(noteId: String) async throws
}
