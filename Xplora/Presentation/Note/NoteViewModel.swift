//
//  NoteViewModel.swift
//  Xplora
//

import Foundation
import PhotosUI
import UIKit

enum NoteViewMode {
    case view
    case edit
}

struct NoteViewState: Equatable {
    let isLoading: Bool
    let mode: NoteViewMode
    let title: String
    let placeTitle: String
    let text: String
    let locationTitle: String
    let locationSubtitle: String
    let hasLocation: Bool
    let locationCoordinate: LocationCoordinate?
    let dateText: String
    let tripStartDate: Date?
    let tripEndDate: Date?
    let fallbackDate: Date
    let isSaveEnabled: Bool
    let isDeleteVisible: Bool
    let isBookmarked: Bool
    let canToggleBookmark: Bool
    let canSearch: Bool
    let hasUnsavedChanges: Bool
    let photoURLs: [URL]
    let canAddPhoto: Bool
    let preselectedAssetIdentifiers: [String]
}

@MainActor
protocol NoteViewModelInput: AnyObject {
    func viewDidLoad()
    func didChangeTitle(_ title: String?)
    func didChangeText(_ text: String)
    func didTapSave()
    func didTapDeleteConfirmed()
    func didTapEdit()
    func didTapCancelEdit()
    func didToggleBookmark()
    func didTapSearch()
    func didTapAddPhoto()
    func didCapturePhoto(_ image: UIImage)
    func didFinishPhotoLibraryPicking(results: [PHPickerResult])
    func didRemovePhoto(at index: Int)
    func didSelectLocation(placeName: String, address: String?, countryCode: String?, latitude: Double, longitude: Double)
    func didRemoveLocation()
    func didUpdateTripDateRange(startDate: Date, endDate: Date)
}

@MainActor
protocol NoteViewModelOutput: AnyObject {
    var onStateChange: ((NoteViewState) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onSearchRequested: (() -> Void)? { get set }
    var onPhotoSourceRequested: (() -> Void)? { get set }
}

@MainActor
final class NoteViewModel: NoteViewModelInput, NoteViewModelOutput {
    var onStateChange: ((NoteViewState) -> Void)?
    var onError: ((String) -> Void)?
    var onSearchRequested: (() -> Void)?
    var onPhotoSourceRequested: (() -> Void)?

    private let noteId: String?
    private let initialCoordinate: LocationCoordinate?
    private let getNoteUseCase: GetNoteUseCase
    private let saveNoteUseCase: SaveNoteUseCase
    private let deleteNoteUseCase: DeleteNoteUseCase
    private let photoLibrarySelectionProcessor: NotePhotoLibrarySelectionProcessing
    private let photoStore: NotePhotoStore
    private weak var output: NoteModuleOutput?
    private weak var router: NoteRouter?

    private var originalNote: Note?
    private var draft: Note?
    private var mode: NoteViewMode = .view
    private var isLoading = false
    private let maxPhotoCount = 10
    private var pendingDeletedPhotoPaths = Set<String>()
    /// Content hashes of stored photos, keyed by `localPath`, so duplicate
    /// detection doesn't re-read every file on each import.
    private var photoHashCache: [String: String] = [:]
    private var isImportingPhotos = false
    /// Bumped whenever the draft is replaced, so an import that finishes
    /// after cancel/save doesn't attach photos to the wrong draft.
    private var draftGeneration = 0

    init(
        noteId: String?,
        initialCoordinate: LocationCoordinate?,
        getNoteUseCase: GetNoteUseCase,
        saveNoteUseCase: SaveNoteUseCase,
        deleteNoteUseCase: DeleteNoteUseCase,
        photoLibrarySelectionProcessor: NotePhotoLibrarySelectionProcessing,
        photoStore: NotePhotoStore,
        output: NoteModuleOutput?,
        router: NoteRouter
    ) {
        self.noteId = noteId
        self.initialCoordinate = initialCoordinate
        self.getNoteUseCase = getNoteUseCase
        self.saveNoteUseCase = saveNoteUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
        self.photoLibrarySelectionProcessor = photoLibrarySelectionProcessor
        self.photoStore = photoStore
        self.output = output
        self.router = router
    }

    func viewDidLoad() {
        if let noteId {
            loadNote(id: noteId)
        } else {
            createDraftForNewNote()
        }
    }

    func didChangeTitle(_ title: String?) {
        guard var current = draft else { return }
        current.title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = current
        publish()
    }

    func didChangeText(_ text: String) {
        guard var current = draft else { return }
        current.text = text
        draft = current
        publish()
    }

    func didTapSave() {
        guard var current = draft else { return }
        if originalNote != nil && !hasUnsavedChanges(current) {
            mode = .view
            publish()
            return
        }
        guard isSaveEnabled(for: current) else { return }

        isLoading = true
        publish()

        let normalizedRange = NoteDateRangeNormalizer.normalizedRange(
            start: current.tripStartDate,
            end: current.tripEndDate
        )
        current.tripStartDate = normalizedRange.start
        current.tripEndDate = normalizedRange.end
        current.updatedAt = Date()
        Task {
            do {
                let saved = try await saveNoteUseCase.execute(note: current)
                let normalizedSaved = normalizedNote(saved)
                finalizePendingPhotoFileDeletion(with: saved)
                originalNote = normalizedSaved
                draft = normalizedSaved
                draftGeneration += 1
                mode = .view
                isLoading = false
                publish()
                output?.noteModuleDidSave(note: normalizedSaved)
            } catch {
                isLoading = false
                publish()
                onError?(L10n.Notes.Editor.Error.save)
            }
        }
    }

    func didTapDeleteConfirmed() {
        guard let note = originalNote else { return }
        isLoading = true
        publish()

        Task {
            do {
                try await deleteNoteUseCase.execute(noteId: note.id)
                deleteAllPhotoFiles(noteId: note.id)
                pendingDeletedPhotoPaths.removeAll()
                isLoading = false
                publish()
                output?.noteModuleDidDelete(noteId: note.id)
                router?.closeNote()
            } catch {
                isLoading = false
                publish()
                onError?(L10n.Notes.Editor.Error.delete)
            }
        }
    }

    func didTapEdit() {
        guard originalNote != nil else { return }
        mode = .edit
        publish()
    }

    func didTapCancelEdit() {
        if let originalNote {
            cleanupUnsavedDraftFiles(keeping: originalNote)
            pendingDeletedPhotoPaths.removeAll()
            draft = originalNote
            draftGeneration += 1
            mode = .view
            publish()
        } else {
            cleanupAllDraftFiles()
            pendingDeletedPhotoPaths.removeAll()
            draftGeneration += 1
            router?.closeNote()
        }
    }

    func didToggleBookmark() {
        guard var current = draft else { return }
        guard originalNote != nil else { return }
        let previous = current
        current.isBookmarked.toggle()
        draft = current
        publish()

        isLoading = true
        publish()

        Task {
            do {
                let saved = try await saveNoteUseCase.execute(note: current)
                let normalizedSaved = normalizedNote(saved)
                originalNote = normalizedSaved
                draft = normalizedSaved
                isLoading = false
                publish()
                output?.noteModuleDidSave(note: normalizedSaved)
            } catch {
                draft = previous
                isLoading = false
                publish()
                onError?(L10n.Notes.Editor.Error.bookmark)
            }
        }
    }

    func didTapSearch() {
        onSearchRequested?()
    }

    func didTapAddPhoto() {
        guard mode == .edit else { return }
        guard !isImportingPhotos else { return }
        guard let current = draft else { return }
        guard current.photos.count < maxPhotoCount else {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }
        onPhotoSourceRequested?()
    }

    func didCapturePhoto(_ image: UIImage) {
        guard mode == .edit, !isImportingPhotos else { return }
        isImportingPhotos = true
        let processor = photoLibrarySelectionProcessor

        Task { [weak self] in
            // Runs off the main actor: downsampling, JPEG encoding, hashing.
            let prepared = await processor.prepareCapturedPhoto(image)
            guard let self else { return }
            await self.addPreparedPhotos(
                prepared.map { [$0] } ?? [],
                failedCount: prepared == nil ? 1 : 0
            )
        }
    }

    func didFinishPhotoLibraryPicking(results: [PHPickerResult]) {
        guard mode == .edit, !isImportingPhotos else { return }
        isImportingPhotos = true

        // The library picker is an "add more" workflow only. Existing photos
        // are passed in as `preselectedAssetIdentifiers` for visual context,
        // but we never sync deselections back — a cancelled picker returns
        // an empty results array, which would otherwise wipe the entire
        // gallery. Removal is exclusively driven by the cross button on the
        // photo cell (`didRemovePhoto(at:)`).
        let existingAssetIdentifiers = Set(draft?.photos.compactMap(\.photoLibraryAssetId) ?? [])
        let processor = photoLibrarySelectionProcessor

        Task { [weak self] in
            let selectionResult = await processor.process(
                results: results,
                existingAssetIdentifiers: existingAssetIdentifiers
            )
            guard let self else { return }
            await self.addPreparedPhotos(
                selectionResult.preparedPhotos,
                failedCount: selectionResult.failedCount
            )
        }
    }

    /// Dedupes, writes files (off the main actor via the store) and appends
    /// the new photos to the draft in the order given.
    private func addPreparedPhotos(_ preparedPhotos: [NotePreparedPhoto], failedCount initialFailedCount: Int) async {
        defer { isImportingPhotos = false }
        guard mode == .edit, let startDraft = draft else { return }
        let noteId = startDraft.id
        let generation = draftGeneration

        guard !preparedPhotos.isEmpty else {
            if initialFailedCount > 0 {
                onError?(L10n.Notes.Editor.Error.Photo.addFailed)
            }
            return
        }

        let existingPhotos = normalizePhotos(startDraft.photos)
        let availableSlots = maxPhotoCount - existingPhotos.count
        guard availableSlots > 0 else {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        var knownAssetIdentifiers = Set(existingPhotos.compactMap(\.photoLibraryAssetId))
        var knownHashes = await storedPhotoHashes(for: existingPhotos)

        var addedPhotos: [NotePhoto] = []
        var duplicateCount = 0
        var failedCount = initialFailedCount
        var limitReached = false

        for prepared in preparedPhotos {
            if addedPhotos.count >= availableSlots {
                limitReached = true
                break
            }
            if let assetIdentifier = prepared.assetIdentifier,
               knownAssetIdentifiers.contains(assetIdentifier) {
                duplicateCount += 1
                continue
            }
            if knownHashes.contains(prepared.contentHash) {
                duplicateCount += 1
                continue
            }

            do {
                let localPath = try await photoStore.savePhoto(prepared.jpegData, noteId: noteId)
                addedPhotos.append(
                    NotePhoto(
                        id: UUID().uuidString,
                        localPath: localPath,
                        createdAt: Date(),
                        orderIndex: existingPhotos.count + addedPhotos.count,
                        photoLibraryAssetId: prepared.assetIdentifier
                    )
                )
                photoHashCache[localPath] = prepared.contentHash
                knownHashes.insert(prepared.contentHash)
                if let assetIdentifier = prepared.assetIdentifier {
                    knownAssetIdentifiers.insert(assetIdentifier)
                }
            } catch {
                failedCount += 1
            }
        }

        // The draft may have been cancelled or saved while files were written.
        guard mode == .edit, draftGeneration == generation, var current = draft, current.id == noteId else {
            deletePhotoFiles(addedPhotos.map(\.localPath))
            return
        }

        guard !addedPhotos.isEmpty else {
            if duplicateCount > 0 {
                onError?(L10n.Notes.Editor.Error.Photo.Duplicate.single)
            } else if failedCount > 0 {
                onError?(L10n.Notes.Editor.Error.Photo.addFailed)
            }
            return
        }

        // Merge into the latest draft so edits made during the import are kept.
        current.photos = normalizePhotos(normalizePhotos(current.photos) + addedPhotos)
        draft = current
        publish()

        if limitReached {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
        } else if duplicateCount > 0 {
            onError?(L10n.Notes.Editor.Error.Photo.skippedDuplicates)
        } else if failedCount > 0 {
            onError?(L10n.Notes.Editor.Error.Photo.skippedFailed)
        }
    }

    private func storedPhotoHashes(for photos: [NotePhoto]) async -> Set<String> {
        var hashes = Set<String>()
        for photo in photos {
            if let cached = photoHashCache[photo.localPath] {
                hashes.insert(cached)
                continue
            }
            // A missing/unreadable file just can't be matched; the store logs it.
            guard let hash = try? await photoStore.contentHash(ofPhotoAt: photo.localPath) else { continue }
            photoHashCache[photo.localPath] = hash
            hashes.insert(hash)
        }
        return hashes
    }

    func didRemovePhoto(at index: Int) {
        guard var current = draft else { return }
        var photos = normalizePhotos(current.photos)
        guard photos.indices.contains(index) else { return }
        let removedPhoto = photos.remove(at: index)
        handleRemovedPhotoFileLifecycle(photo: removedPhoto)
        current.photos = normalizePhotos(photos)
        draft = current
        publish()
    }

    func didSelectLocation(placeName: String, address: String?, countryCode: String?, latitude: Double, longitude: Double) {
        guard var current = draft else { return }
        let trimmedName = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let (city, country) = NoteLocationAddressParser.parseCityCountry(from: address)
        current.location = NoteLocation(
            placeName: trimmedName,
            city: city,
            country: country,
            countryCode: countryCode,
            latitude: latitude,
            longitude: longitude
        )
        draft = current
        publish()
    }

    func didRemoveLocation() {
        guard var current = draft else { return }
        current.location = nil
        draft = current
        publish()
    }

    func didUpdateTripDateRange(startDate: Date, endDate: Date) {
        guard var current = draft else { return }
        let normalizedRange = NoteDateRangeNormalizer.normalizedRange(start: startDate, end: endDate)
        current.tripStartDate = normalizedRange.start
        current.tripEndDate = normalizedRange.end
        draft = current
        publish()
    }

    private func loadNote(id: String) {
        isLoading = true
        publish()

        Task {
            do {
                let note = try await getNoteUseCase.execute(id: id)
                let normalizedNote = normalizedNote(note)
                originalNote = normalizedNote
                draft = normalizedNote
                mode = .view
                isLoading = false
                publish()
            } catch {
                isLoading = false
                publish()
                onError?(L10n.Notes.Editor.Error.load)
            }
        }
    }

    private func createDraftForNewNote() {
        let now = Date()
        let note = Note(
            id: UUID().uuidString,
            title: nil,
            text: "",
            createdAt: now,
            updatedAt: now,
            tripStartDate: nil,
            tripEndDate: nil,
            isBookmarked: false,
            location: nil,
            photos: [],
            headerTitle: nil
        )
        originalNote = nil
        draft = note
        mode = .edit
        isLoading = false
        publish()
    }

    private func publish() {
        guard let current = draft else { return }
        let normalizedRange = effectiveDateRange(for: current)
        let orderedPhotos = normalizePhotos(current.photos)
        let photoURLs = orderedPhotos.map { NotePhotoFileStorage.absoluteURL(for: $0.localPath) }
        let preselectedAssetIdentifiers = orderedPhotos.compactMap(\.photoLibraryAssetId)
        let hasLocationText = current.location?.hasDisplayableValue == true
        let locationCoordinate = hasLocationText ? current.coordinate : nil
        let state = NoteViewState(
            isLoading: isLoading,
            mode: mode,
            title: current.title ?? "",
            placeTitle: NotePresentationTitle.displayTitle(from: current.title),
            text: current.text,
            locationTitle: hasLocationText ? (current.location?.placeName ?? "") : "",
            locationSubtitle: hasLocationText ? (current.location?.address ?? "") : "",
            hasLocation: hasLocationText,
            locationCoordinate: locationCoordinate,
            dateText: formatDateText(for: current),
            tripStartDate: normalizedRange.start,
            tripEndDate: normalizedRange.end,
            fallbackDate: current.createdAt,
            isSaveEnabled: isSaveEnabled(for: current),
            isDeleteVisible: originalNote != nil,
            isBookmarked: current.isBookmarked,
            canToggleBookmark: originalNote != nil,
            canSearch: !current.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasUnsavedChanges: hasUnsavedChanges(current),
            photoURLs: photoURLs,
            canAddPhoto: mode == .edit && orderedPhotos.count < maxPhotoCount,
            preselectedAssetIdentifiers: preselectedAssetIdentifiers
        )
        onStateChange?(state)
    }

    private func isSaveEnabled(for note: Note) -> Bool {
        let hasTitle = !(note.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasText = !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = note.location?.hasDisplayableValue == true
        let hasPhotos = !note.photos.isEmpty
        let hasDateRange = note.tripStartDate != nil || note.tripEndDate != nil

        guard hasTitle || hasText || hasLocation || hasPhotos || hasDateRange else { return false }
        if let original = originalNote {
            return original != note
        }
        return true
    }

    private func hasUnsavedChanges(_ note: Note) -> Bool {
        guard let original = originalNote else {
            let hasTitle = !(note.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasTitle
                || !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || note.location?.hasDisplayableValue == true
                || !note.photos.isEmpty
                || note.tripStartDate != nil
                || note.tripEndDate != nil
        }
        return original != note
    }

    private func formatDateText(for note: Note) -> String {
        let resolvedRange = NoteDateRangeResolver.effectiveRange(
            tripStartDate: note.tripStartDate,
            tripEndDate: note.tripEndDate
        )
        if let start = resolvedRange.start, let end = resolvedRange.end {
            return NoteDateRangeFormatter.displayText(startDate: start, endDate: end)
        }
        return NoteDateRangeFormatter.displayText(for: note.createdAt)
    }

    private func effectiveDateRange(for note: Note) -> (start: Date?, end: Date?) {
        NoteDateRangeResolver.effectiveRange(
            tripStartDate: note.tripStartDate,
            tripEndDate: note.tripEndDate
        )
    }

    private func normalizedNote(_ note: Note) -> Note {
        var mutableNote = note
        let normalizedRange = effectiveDateRange(for: note)
        mutableNote.tripStartDate = normalizedRange.start
        mutableNote.tripEndDate = normalizedRange.end
        return mutableNote
    }

    private func handleRemovedPhotoFileLifecycle(photo: NotePhoto) {
        let wasPersistedInOriginal = originalNote?.photos.contains(where: { $0.id == photo.id }) ?? false
        if wasPersistedInOriginal {
            pendingDeletedPhotoPaths.insert(photo.localPath)
        } else {
            deletePhotoFiles([photo.localPath])
        }
    }

    private func finalizePendingPhotoFileDeletion(with saved: Note) {
        let retainedPaths = Set(saved.photos.map(\.localPath))
        deletePhotoFiles(pendingDeletedPhotoPaths.filter { !retainedPaths.contains($0) }.sorted())
        pendingDeletedPhotoPaths.removeAll()
    }

    private func cleanupUnsavedDraftFiles(keeping original: Note) {
        guard let currentDraft = draft else { return }
        let originalPhotoIDs = Set(original.photos.map(\.id))
        let unsavedPaths = currentDraft.photos
            .filter { !originalPhotoIDs.contains($0.id) }
            .map(\.localPath)
        deletePhotoFiles(unsavedPaths)
    }

    private func cleanupAllDraftFiles() {
        guard let currentDraft = draft else { return }
        deleteAllPhotoFiles(noteId: currentDraft.id)
    }

    // Deletion is best-effort: a leftover file doesn't affect the note, and
    // failures are logged by the store.
    private func deletePhotoFiles(_ localPaths: [String]) {
        guard !localPaths.isEmpty else { return }
        for localPath in localPaths {
            photoHashCache.removeValue(forKey: localPath)
        }
        Task { [photoStore] in
            for localPath in localPaths {
                try? await photoStore.deletePhoto(at: localPath)
            }
        }
    }

    private func deleteAllPhotoFiles(noteId: String) {
        photoHashCache.removeAll()
        Task { [photoStore] in
            try? await photoStore.deleteAllPhotos(noteId: noteId)
        }
    }

    private func normalizePhotos(_ photos: [NotePhoto]) -> [NotePhoto] {
        photos
            .sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.orderIndex < rhs.orderIndex
            }
            .enumerated()
            .map { index, photo in
                var mutablePhoto = photo
                mutablePhoto.orderIndex = index
                return mutablePhoto
            }
    }
}
