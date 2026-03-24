//
//  GetAllNotesUseCase.swift
//  Xplora
//

import Foundation

protocol GetAllNotesUseCase {
    func execute() async throws -> [Note]
}

final class GetAllNotesUseCaseImpl: GetAllNotesUseCase {
    private let notesRepo: NotesRepo

    init(notesRepo: NotesRepo) {
        self.notesRepo = notesRepo
    }

    func execute() async throws -> [Note] {
        try await notesRepo.fetchAllNotes()
    }
}
