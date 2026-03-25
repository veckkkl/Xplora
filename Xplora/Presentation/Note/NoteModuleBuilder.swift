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
    private let notePhotoStorage: NotePhotoStorage

    init(
        getNoteUseCase: GetNoteUseCase,
        saveNoteUseCase: SaveNoteUseCase,
        deleteNoteUseCase: DeleteNoteUseCase,
        notePhotoStorage: NotePhotoStorage
    ) {
        self.getNoteUseCase = getNoteUseCase
        self.saveNoteUseCase = saveNoteUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
        self.notePhotoStorage = notePhotoStorage
    }

    func build(noteId: String?, coordinate: LocationCoordinate?, output: NoteModuleOutput?, router: NoteRouter) -> UIViewController {
        let viewModel = NoteViewModel(
            noteId: noteId,
            initialCoordinate: coordinate,
            getNoteUseCase: getNoteUseCase,
            saveNoteUseCase: saveNoteUseCase,
            deleteNoteUseCase: deleteNoteUseCase,
            notePhotoStorage: notePhotoStorage,
            output: output,
            router: router
        )
        return NoteViewController(viewModel: viewModel)
    }
}
