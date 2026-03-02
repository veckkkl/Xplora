//
//  NoteModuleBuilder.swift
//  Xplora
//

import UIKit

@MainActor
final class NoteModuleBuilder {
    private let getNoteUseCase: GetNoteUseCase
    private let saveNoteUseCase: SaveNoteUseCase
    private let deleteNoteUseCase: DeleteNoteUseCase

    init(getNoteUseCase: GetNoteUseCase, saveNoteUseCase: SaveNoteUseCase, deleteNoteUseCase: DeleteNoteUseCase) {
        self.getNoteUseCase = getNoteUseCase
        self.saveNoteUseCase = saveNoteUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
    }

    func build(noteId: String?, coordinate: LocationCoordinate?, output: NoteModuleOutput?, router: NoteRouter) -> UIViewController {
        let viewModel = NoteViewModel(
            noteId: noteId,
            initialCoordinate: coordinate,
            getNoteUseCase: getNoteUseCase,
            saveNoteUseCase: saveNoteUseCase,
            deleteNoteUseCase: deleteNoteUseCase,
            output: output,
            router: router
        )
        return NoteViewController(viewModel: viewModel)
    }
}
