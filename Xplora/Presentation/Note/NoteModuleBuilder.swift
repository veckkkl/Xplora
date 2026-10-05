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
    private let photoStore: NotePhotoStore

    init(
        getNoteUseCase: GetNoteUseCase,
        saveNoteUseCase: SaveNoteUseCase,
        deleteNoteUseCase: DeleteNoteUseCase,
        photoStore: NotePhotoStore
    ) {
        self.getNoteUseCase = getNoteUseCase
        self.saveNoteUseCase = saveNoteUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
        self.photoStore = photoStore
    }

    func build(noteId: String?, coordinate: LocationCoordinate?, output: NoteModuleOutput?, router: NoteRouter) -> UIViewController {
        let viewModel = NoteViewModel(
            noteId: noteId,
            initialCoordinate: coordinate,
            getNoteUseCase: getNoteUseCase,
            saveNoteUseCase: saveNoteUseCase,
            deleteNoteUseCase: deleteNoteUseCase,
            photoLibrarySelectionProcessor: NotePhotoLibrarySelectionProcessor(),
            photoStore: photoStore,
            output: output,
            router: router
        )
        return NoteViewController(viewModel: viewModel)
    }
}
