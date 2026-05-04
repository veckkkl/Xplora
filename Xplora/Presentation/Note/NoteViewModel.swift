//
//  NoteViewModel.swift
//  Xplora
//

import Foundation
import CryptoKit
import PhotosUI
import UIKit

enum NoteViewMode {
    case view
    case edit
}

struct NotePickedPhoto {
    let image: UIImage
    let assetIdentifier: String?
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
    func didSelectLocation(placeName: String, address: String?, latitude: Double, longitude: Double)
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
    private weak var output: NoteModuleOutput?
    private weak var router: NoteRouter?

    private var originalNote: Note?
    private var draft: Note?
    private var mode: NoteViewMode = .view
    private var isLoading = false
    private let maxPhotoCount = 10
    private var pendingDeletedPhotoPaths = Set<String>()

    init(
        noteId: String?,
        initialCoordinate: LocationCoordinate?,
        getNoteUseCase: GetNoteUseCase,
        saveNoteUseCase: SaveNoteUseCase,
        deleteNoteUseCase: DeleteNoteUseCase,
        photoLibrarySelectionProcessor: NotePhotoLibrarySelectionProcessing,
        output: NoteModuleOutput?,
        router: NoteRouter
    ) {
        self.noteId = noteId
        self.initialCoordinate = initialCoordinate
        self.getNoteUseCase = getNoteUseCase
        self.saveNoteUseCase = saveNoteUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
        self.photoLibrarySelectionProcessor = photoLibrarySelectionProcessor
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
                cleanupFiles(for: note.photos)
                clearEmptyNotesDirectory(noteId: note.id)
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
            mode = .view
            publish()
        } else {
            cleanupAllDraftFiles()
            pendingDeletedPhotoPaths.removeAll()
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
        guard let current = draft else { return }
        guard current.photos.count < maxPhotoCount else {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }
        onPhotoSourceRequested?()
    }

    func didCapturePhoto(_ image: UIImage) {
        didAddPhotos([NotePickedPhoto(image: image, assetIdentifier: nil)])
    }

    func didFinishPhotoLibraryPicking(results: [PHPickerResult]) {
        guard mode == .edit else { return }

        let existingAssetIdentifiers = Set(draft?.photos.compactMap(\.photoLibraryAssetId) ?? [])
        Task { [weak self] in
            guard let self else { return }
            let selectionResult = await self.photoLibrarySelectionProcessor.process(
                results: results,
                existingAssetIdentifiers: existingAssetIdentifiers
            )
            self.didCompletePhotoLibrarySelection(
                selectedAssetIdentifiers: selectionResult.selectedAssetIdentifiers,
                newlyPickedPhotos: selectionResult.newlyPickedPhotos
            )
        }
    }

    private func didAddPhotos(_ photos: [NotePickedPhoto]) {
        guard mode == .edit else { return }
        guard !photos.isEmpty else { return }
        guard var current = draft else { return }

        let normalizedExistingPhotos = normalizePhotos(current.photos)
        var existingAssetIdentifiers = Set(normalizedExistingPhotos.compactMap(\.photoLibraryAssetId))
        var existingHashes = Set(normalizedExistingPhotos.compactMap { fileHash(for: URL(fileURLWithPath: $0.localPath)) })
        var addedHashes = Set<String>()
        var updatedPhotos = normalizedExistingPhotos
        let availableSlots = maxPhotoCount - updatedPhotos.count
        guard availableSlots > 0 else {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        var addedCount = 0
        var duplicateCount = 0
        var failedCount = 0
        var limitReached = false

        for pickedPhoto in photos {
            if updatedPhotos.count >= maxPhotoCount {
                limitReached = true
                break
            }

            if let assetIdentifier = pickedPhoto.assetIdentifier,
               existingAssetIdentifiers.contains(assetIdentifier) {
                duplicateCount += 1
                continue
            }

            let image = pickedPhoto.image
            guard let data = image.jpegData(compressionQuality: 0.82) else {
                failedCount += 1
                continue
            }

            let hash = sha256Hex(data)
            if existingHashes.contains(hash) || addedHashes.contains(hash) {
                duplicateCount += 1
                continue
            }

            do {
                let fileURL = try saveImageData(data, noteId: current.id)
                let photo = NotePhoto(
                    id: UUID().uuidString,
                    localPath: fileURL.path,
                    createdAt: Date(),
                    orderIndex: updatedPhotos.count,
                    photoLibraryAssetId: pickedPhoto.assetIdentifier
                )
                updatedPhotos.append(photo)
                existingHashes.insert(hash)
                addedHashes.insert(hash)
                if let assetIdentifier = pickedPhoto.assetIdentifier {
                    existingAssetIdentifiers.insert(assetIdentifier)
                }
                addedCount += 1
            } catch {
                failedCount += 1
            }
        }

        guard addedCount > 0 else {
            if duplicateCount > 0 {
                onError?(L10n.Notes.Editor.Error.Photo.Duplicate.single)
            } else if failedCount > 0 {
                onError?(L10n.Notes.Editor.Error.Photo.addFailed)
            }
            return
        }

        current.photos = normalizePhotos(updatedPhotos)
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

    private func didCompletePhotoLibrarySelection(selectedAssetIdentifiers: Set<String>, newlyPickedPhotos: [NotePickedPhoto]) {
        guard mode == .edit else { return }
        guard var current = draft else { return }

        var photos = normalizePhotos(current.photos)
        let removedPhotos = photos.filter { photo in
            guard let assetIdentifier = photo.photoLibraryAssetId else { return false }
            return !selectedAssetIdentifiers.contains(assetIdentifier)
        }
        if !removedPhotos.isEmpty {
            for photo in removedPhotos {
                handleRemovedPhotoFileLifecycle(photo: photo)
            }
            photos.removeAll { photo in
                guard let assetIdentifier = photo.photoLibraryAssetId else { return false }
                return !selectedAssetIdentifiers.contains(assetIdentifier)
            }
            current.photos = normalizePhotos(photos)
            draft = current
            publish()
        }

        guard !newlyPickedPhotos.isEmpty else { return }
        didAddPhotos(newlyPickedPhotos)
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

    func didSelectLocation(placeName: String, address: String?, latitude: Double, longitude: Double) {
        guard var current = draft else { return }
        let trimmedName = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let (city, country) = parseCityCountry(from: address)
        current.location = NoteLocation(
            placeName: trimmedName,
            city: city,
            country: country,
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
        let photoURLs = orderedPhotos.map { URL(fileURLWithPath: $0.localPath) }
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

    private func parseCityCountry(from address: String?) -> (String, String) {
        let trimmed = address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return ("", "") }
        let parts = trimmed
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            return (parts[parts.count - 2], parts[parts.count - 1])
        }

        return (parts.first ?? "", "")
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

    private func saveImageData(_ data: Data, noteId: String) throws -> URL {
        let directoryURL = try notesDirectoryURL(noteId: noteId)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let fileURL = directoryURL.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func handleRemovedPhotoFileLifecycle(photo: NotePhoto) {
        let wasPersistedInOriginal = originalNote?.photos.contains(where: { $0.id == photo.id }) ?? false
        if wasPersistedInOriginal {
            pendingDeletedPhotoPaths.insert(photo.localPath)
        } else {
            removeFile(at: photo.localPath)
        }
    }

    private func finalizePendingPhotoFileDeletion(with saved: Note) {
        let retainedPaths = Set(saved.photos.map(\.localPath))
        for path in pendingDeletedPhotoPaths where !retainedPaths.contains(path) {
            removeFile(at: path)
        }
        pendingDeletedPhotoPaths.removeAll()
    }

    private func cleanupUnsavedDraftFiles(keeping original: Note) {
        guard let currentDraft = draft else { return }
        let originalPhotoIDs = Set(original.photos.map(\.id))
        for photo in currentDraft.photos where !originalPhotoIDs.contains(photo.id) {
            removeFile(at: photo.localPath)
        }
    }

    private func cleanupAllDraftFiles() {
        guard let currentDraft = draft else { return }
        cleanupFiles(for: currentDraft.photos)
        clearEmptyNotesDirectory(noteId: currentDraft.id)
    }

    private func cleanupFiles(for photos: [NotePhoto]) {
        for photo in photos {
            removeFile(at: photo.localPath)
        }
    }

    private func removeFile(at localPath: String) {
        let url = URL(fileURLWithPath: localPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func clearEmptyNotesDirectory(noteId: String) {
        guard let directoryURL = try? notesDirectoryURL(noteId: noteId) else { return }
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else { return }
        guard contents.isEmpty else { return }
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func notesDirectoryURL(noteId: String) throws -> URL {
        let baseDirectory = try applicationSupportDirectoryURL()
        return baseDirectory
            .appendingPathComponent("Notes", isDirectory: true)
            .appendingPathComponent(noteId, isDirectory: true)
    }

    private func applicationSupportDirectoryURL() throws -> URL {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "NoteViewModel", code: 1)
        }

        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private func fileHash(for url: URL) -> String? {
        guard url.isFileURL else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return sha256Hex(data)
    }

    private func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
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
