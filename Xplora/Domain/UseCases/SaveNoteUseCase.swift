//
//  SaveNoteUseCase.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

protocol SaveNoteUseCase {
    func execute(note: Note) async throws -> Note
}

final class SaveNoteUseCaseImpl: SaveNoteUseCase {
    private let notesRepo: NotesRepo

    init(notesRepo: NotesRepo) {
        self.notesRepo = notesRepo
    }

    func execute(note: Note) async throws -> Note {
        try await notesRepo.save(note: note)
    }
}
