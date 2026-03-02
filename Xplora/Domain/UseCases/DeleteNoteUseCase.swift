//
//  DeleteNoteUseCase.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

protocol DeleteNoteUseCase {
    func execute(noteId: String) async throws
}

final class DeleteNoteUseCaseImpl: DeleteNoteUseCase {
    private let notesRepo: NotesRepo

    init(notesRepo: NotesRepo) {
        self.notesRepo = notesRepo
    }

    func execute(noteId: String) async throws {
        try await notesRepo.delete(noteId: noteId)
    }
}
