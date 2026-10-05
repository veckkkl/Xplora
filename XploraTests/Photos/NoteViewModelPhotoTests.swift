//
//  NoteViewModelPhotoTests.swift
//  XploraTests
//

import Foundation
import PhotosUI
import Testing
import UIKit
@testable import Xplora

// MARK: - Mocks

private final class InMemoryNotePhotoStore: NotePhotoStore, @unchecked Sendable {
    private let lock = NSLock()
    private var files: [String: Data] = [:]
    private var saveCount = 0
    private(set) var savedOrder: [Data] = []
    private(set) var deletedAllNoteIds: [String] = []
    var saveError: Error?

    var fileCount: Int { lock.withLock { files.count } }

    func savePhoto(_ jpegData: Data, noteId: String) async throws -> String {
        try lock.withLock {
            if let saveError { throw saveError }
            let path = "Notes/\(noteId)/photo\(saveCount).jpg"
            saveCount += 1
            files[path] = jpegData
            savedOrder.append(jpegData)
            return path
        }
    }

    func loadPhotoData(at localPath: String) async throws -> Data {
        try lock.withLock {
            guard let data = files[localPath] else { throw CocoaError(.fileNoSuchFile) }
            return data
        }
    }

    func contentHash(ofPhotoAt localPath: String) async throws -> String {
        NotePhotoImageProcessor.sha256Hex(try await loadPhotoData(at: localPath))
    }

    func deletePhoto(at localPath: String) async throws {
        lock.withLock { _ = files.removeValue(forKey: localPath) }
    }

    func deleteAllPhotos(noteId: String) async throws {
        lock.withLock {
            deletedAllNoteIds.append(noteId)
            files = files.filter { !$0.key.hasPrefix("Notes/\(noteId)/") }
        }
    }
}

private final class StubPhotoProcessor: NotePhotoLibrarySelectionProcessing {
    var libraryPhotos: [NotePreparedPhoto] = []
    var libraryFailedCount = 0
    var capturedPhoto: NotePreparedPhoto?

    func process(results: [PHPickerResult], existingAssetIdentifiers: Set<String>) async -> NotePhotoLibrarySelectionResult {
        NotePhotoLibrarySelectionResult(
            selectedAssetIdentifiers: [],
            preparedPhotos: libraryPhotos,
            failedCount: libraryFailedCount
        )
    }

    func prepareCapturedPhoto(_ image: UIImage) async -> NotePreparedPhoto? {
        capturedPhoto
    }
}

private final class StubGetNoteUseCase: GetNoteUseCase {
    var note: Note?
    func execute(id: String) async throws -> Note {
        guard let note else { throw NoteRepositoryError.notFound }
        return note
    }
}

private final class StubSaveNoteUseCase: SaveNoteUseCase {
    func execute(note: Note) async throws -> Note { note }
}

private final class StubDeleteNoteUseCase: DeleteNoteUseCase {
    func execute(noteId: String) async throws {}
}

private final class StubNoteRouter: NoteRouter {
    private(set) var closeCount = 0
    func showNote(noteId: String?, coordinate: LocationCoordinate?, output: NoteModuleOutput?) {}
    func closeNote() { closeCount += 1 }
}

// MARK: - Tests

@MainActor
struct NoteViewModelPhotoTests {

    private struct SUT {
        let viewModel: NoteViewModel
        let store: InMemoryNotePhotoStore
        let processor: StubPhotoProcessor
        let getNote: StubGetNoteUseCase
        let router: StubNoteRouter
    }

    private func makeSUT(existingNote: Note? = nil) -> SUT {
        let store = InMemoryNotePhotoStore()
        let processor = StubPhotoProcessor()
        let getNote = StubGetNoteUseCase()
        getNote.note = existingNote
        let router = StubNoteRouter()
        let viewModel = NoteViewModel(
            noteId: existingNote?.id,
            initialCoordinate: nil,
            getNoteUseCase: getNote,
            saveNoteUseCase: StubSaveNoteUseCase(),
            deleteNoteUseCase: StubDeleteNoteUseCase(),
            photoLibrarySelectionProcessor: processor,
            photoStore: store,
            output: nil,
            router: router
        )
        return SUT(viewModel: viewModel, store: store, processor: processor, getNote: getNote, router: router)
    }

    private func prepared(_ content: String, assetIdentifier: String? = nil) -> NotePreparedPhoto {
        let data = Data(content.utf8)
        return NotePreparedPhoto(
            jpegData: data,
            contentHash: NotePhotoImageProcessor.sha256Hex(data),
            assetIdentifier: assetIdentifier
        )
    }

    /// Waits for the view model's background tasks to settle.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: - Ordering

    @Test func libraryPick_keepsSelectionOrder() async {
        let sut = makeSUT()
        var state: NoteViewState?
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = [prepared("1", assetIdentifier: "a1"), prepared("2", assetIdentifier: "a2"), prepared("3", assetIdentifier: "a3")]

        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { state?.photoURLs.count == 3 }

        #expect(sut.store.savedOrder == [Data("1".utf8), Data("2".utf8), Data("3".utf8)])
        #expect(state?.photoURLs.map(\.lastPathComponent) == ["photo0.jpg", "photo1.jpg", "photo2.jpg"])
        #expect(state?.preselectedAssetIdentifiers == ["a1", "a2", "a3"])
    }

    // MARK: - Duplicates

    @Test func libraryPick_sameContentTwice_addsOnce() async {
        let sut = makeSUT()
        var state: NoteViewState?
        var errors: [String] = []
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.onError = { errors.append($0) }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = [prepared("same"), prepared("same")]

        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { state?.photoURLs.count == 1 && !errors.isEmpty }

        #expect(state?.photoURLs.count == 1)
        #expect(sut.store.fileCount == 1)
        #expect(errors == [L10n.Notes.Editor.Error.Photo.skippedDuplicates])
    }

    @Test func capture_duplicateOfStoredPhoto_isRejected() async {
        let sut = makeSUT()
        var state: NoteViewState?
        var errors: [String] = []
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.onError = { errors.append($0) }
        sut.viewModel.viewDidLoad()
        sut.processor.capturedPhoto = prepared("photo")

        sut.viewModel.didCapturePhoto(UIImage())
        await waitUntil { state?.photoURLs.count == 1 }
        sut.viewModel.didCapturePhoto(UIImage())
        await waitUntil { !errors.isEmpty }

        #expect(state?.photoURLs.count == 1)
        #expect(sut.store.fileCount == 1)
        #expect(errors == [L10n.Notes.Editor.Error.Photo.Duplicate.single])
    }

    @Test func libraryPick_existingAssetIdentifier_isRejected() async {
        let sut = makeSUT()
        var state: NoteViewState?
        var errors: [String] = []
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.onError = { errors.append($0) }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = [prepared("1", assetIdentifier: "a1")]
        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { state?.photoURLs.count == 1 }

        sut.processor.libraryPhotos = [prepared("1-reencoded", assetIdentifier: "a1")]
        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { !errors.isEmpty }

        #expect(state?.photoURLs.count == 1)
        #expect(errors == [L10n.Notes.Editor.Error.Photo.Duplicate.single])
    }

    // MARK: - Limits / failures

    @Test func libraryPick_beyondLimit_addsOnlyAvailableSlots() async {
        let sut = makeSUT()
        var state: NoteViewState?
        var errors: [String] = []
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.onError = { errors.append($0) }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = (0..<12).map { prepared("p\($0)") }

        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { !errors.isEmpty }

        #expect(state?.photoURLs.count == 10)
        #expect(state?.canAddPhoto == false)
        #expect(sut.store.fileCount == 10)
    }

    @Test func saveFailure_addsNothingAndReportsError() async {
        let sut = makeSUT()
        var state: NoteViewState?
        var errors: [String] = []
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.onError = { errors.append($0) }
        sut.viewModel.viewDidLoad()
        sut.store.saveError = CocoaError(.fileWriteOutOfSpace)
        sut.processor.libraryPhotos = [prepared("1")]

        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { !errors.isEmpty }

        #expect(state?.photoURLs.isEmpty == true)
        #expect(errors == [L10n.Notes.Editor.Error.Photo.addFailed])
    }

    @Test func processingFailure_isReported() async {
        let sut = makeSUT()
        var errors: [String] = []
        sut.viewModel.onError = { errors.append($0) }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = []
        sut.processor.libraryFailedCount = 2

        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { !errors.isEmpty }

        #expect(errors == [L10n.Notes.Editor.Error.Photo.addFailed])
    }

    // MARK: - File lifecycle

    @Test func removeUnsavedPhoto_deletesItsFile() async {
        let sut = makeSUT()
        var state: NoteViewState?
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = [prepared("1"), prepared("2")]
        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { state?.photoURLs.count == 2 }

        sut.viewModel.didRemovePhoto(at: 0)
        await waitUntil { sut.store.fileCount == 1 }

        #expect(state?.photoURLs.map(\.lastPathComponent) == ["photo1.jpg"])
        #expect(sut.store.fileCount == 1)
    }

    @Test func cancelNewNote_deletesAllDraftPhotos() async {
        let sut = makeSUT()
        var state: NoteViewState?
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.viewDidLoad()
        sut.processor.libraryPhotos = [prepared("1"), prepared("2")]
        sut.viewModel.didFinishPhotoLibraryPicking(results: [])
        await waitUntil { state?.photoURLs.count == 2 }

        sut.viewModel.didTapCancelEdit()
        await waitUntil { sut.store.fileCount == 0 }

        #expect(sut.store.fileCount == 0)
        #expect(sut.router.closeCount == 1)
    }

    @Test func deleteNote_deletesAllItsPhotos() async {
        let note = Note(
            id: "note-1",
            title: "Title",
            text: "",
            createdAt: Date(),
            updatedAt: Date(),
            tripStartDate: nil,
            tripEndDate: nil,
            isBookmarked: false,
            location: nil,
            photos: [NotePhoto(id: "p1", localPath: "Notes/note-1/a.jpg", createdAt: Date(), orderIndex: 0, photoLibraryAssetId: nil)]
        )
        let sut = makeSUT(existingNote: note)
        var state: NoteViewState?
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.viewDidLoad()
        await waitUntil { state?.isLoading == false }

        sut.viewModel.didTapDeleteConfirmed()
        await waitUntil { sut.store.deletedAllNoteIds == ["note-1"] }

        #expect(sut.store.deletedAllNoteIds == ["note-1"])
        #expect(sut.router.closeCount == 1)
    }

    @Test func existingNote_photoOrderIsPreserved() async {
        let photos = [
            NotePhoto(id: "p2", localPath: "Notes/n/b.jpg", createdAt: Date(), orderIndex: 1, photoLibraryAssetId: nil),
            NotePhoto(id: "p1", localPath: "Notes/n/a.jpg", createdAt: Date(), orderIndex: 0, photoLibraryAssetId: nil)
        ]
        let note = Note(
            id: "n", title: "T", text: "", createdAt: Date(), updatedAt: Date(),
            tripStartDate: nil, tripEndDate: nil, isBookmarked: false, location: nil, photos: photos
        )
        let sut = makeSUT(existingNote: note)
        var state: NoteViewState?
        sut.viewModel.onStateChange = { state = $0 }
        sut.viewModel.viewDidLoad()
        await waitUntil { state?.isLoading == false }

        #expect(state?.photoURLs.map(\.lastPathComponent) == ["a.jpg", "b.jpg"])
    }
}
