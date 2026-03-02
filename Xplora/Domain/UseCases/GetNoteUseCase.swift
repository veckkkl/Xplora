//
//  GetNoteUseCase.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

protocol GetNoteUseCase {
    func execute(id: String) async throws -> Note
}

final class GetNoteUseCaseImpl: GetNoteUseCase {
    private let notesRepo: NotesRepo

    init(notesRepo: NotesRepo) {
        self.notesRepo = notesRepo
    }

    func execute(id: String) async throws -> Note {
        try await notesRepo.getNote(id: id)
    }
}
