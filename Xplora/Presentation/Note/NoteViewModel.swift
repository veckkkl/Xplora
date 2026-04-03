//
//  NoteViewModel.swift
//  Xplora
//

import Foundation

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
    let isSaveEnabled: Bool
    let isDeleteVisible: Bool
    let isBookmarked: Bool
    let canToggleBookmark: Bool
    let canSearch: Bool
    let hasUnsavedChanges: Bool
    let photoURLs: [URL]
}

@MainActor
protocol NoteViewModelInput: AnyObject {
    func viewDidLoad()
    func didChangeTitle(_ title: String?)
    func didChangeHeaderTitle(_ title: String?)
    func didChangeText(_ text: String)
    func didTapSave()
    func didTapDeleteConfirmed()
    func didTapEdit()
    func didTapCancelEdit()
    func didToggleBookmark()
    func didTapSearch()
    func didRemovePhoto(at index: Int)
    func didSelectLocation(placeName: String, address: String?, latitude: Double, longitude: Double)
    func didRemoveLocation()
    func didUpdateDateRangeText(_ text: String)
}

@MainActor
protocol NoteViewModelOutput: AnyObject {
    var onStateChange: ((NoteViewState) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onSearchRequested: (() -> Void)? { get set }
}

@MainActor
final class NoteViewModel: NoteViewModelInput, NoteViewModelOutput {
    var onStateChange: ((NoteViewState) -> Void)?
    var onError: ((String) -> Void)?
    var onSearchRequested: (() -> Void)?

    private let noteId: String?
    private let initialCoordinate: LocationCoordinate?
    private let getNoteUseCase: GetNoteUseCase
    private let saveNoteUseCase: SaveNoteUseCase
    private let deleteNoteUseCase: DeleteNoteUseCase
    private weak var output: NoteModuleOutput?
    private weak var router: NoteRouter?

    private var originalNote: Note?
    private var draft: Note?
    private var mode: NoteViewMode = .view
    private var isLoading = false

    init(
        noteId: String?,
        initialCoordinate: LocationCoordinate?,
        getNoteUseCase: GetNoteUseCase,
        saveNoteUseCase: SaveNoteUseCase,
        deleteNoteUseCase: DeleteNoteUseCase,
        output: NoteModuleOutput?,
        router: NoteRouter
    ) {
        self.noteId = noteId
        self.initialCoordinate = initialCoordinate
        self.getNoteUseCase = getNoteUseCase
        self.saveNoteUseCase = saveNoteUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
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

    func didChangeHeaderTitle(_ title: String?) {
        guard var current = draft else { return }
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        current.headerTitle = (trimmed?.isEmpty ?? true) ? nil : trimmed
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

        current.updatedAt = Date()
        Task {
            do {
                let saved = try await saveNoteUseCase.execute(note: current)
                originalNote = saved
                draft = saved
                mode = .view
                isLoading = false
                publish()
                output?.noteModuleDidSave(note: saved)
            } catch {
                isLoading = false
                publish()
                onError?("Couldn't save the note. Please try again.")
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
                isLoading = false
                publish()
                output?.noteModuleDidDelete(noteId: note.id)
                router?.closeNote()
            } catch {
                isLoading = false
                publish()
                onError?("Couldn't delete the note. Please try again.")
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
            draft = originalNote
            mode = .view
            publish()
        } else {
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
                originalNote = saved
                draft = saved
                isLoading = false
                publish()
                output?.noteModuleDidSave(note: saved)
            } catch {
                draft = previous
                isLoading = false
                publish()
                onError?("Couldn't update the bookmark. Please try again.")
            }
        }
    }

    func didTapSearch() {
        onSearchRequested?()
    }

    func didRemovePhoto(at index: Int) {
        guard var current = draft else { return }
        guard current.photoURLs.indices.contains(index) else { return }
        current.photoURLs.remove(at: index)
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
        current.location = NoteLocation(
            placeName: "",
            city: "",
            country: "",
            latitude: current.location.latitude,
            longitude: current.location.longitude
        )
        draft = current
        publish()
    }

    func didUpdateDateRangeText(_ text: String) {
        guard var current = draft else { return }
        current.dateRangeText = text
        draft = current
        publish()
    }

    private func loadNote(id: String) {
        isLoading = true
        publish()

        Task {
            do {
                let note = try await getNoteUseCase.execute(id: id)
                originalNote = note
                draft = note
                mode = .view
                isLoading = false
                publish()
            } catch {
                isLoading = false
                publish()
                onError?("Couldn't load the note. Please try again.")
            }
        }
    }

    private func createDraftForNewNote() {
        let coordinate = initialCoordinate ?? LocationCoordinate(latitude: 0, longitude: 0)
        let now = Date()
        let note = Note(
            id: UUID().uuidString,
            title: nil,
            text: "",
            createdAt: now,
            updatedAt: now,
            isBookmarked: false,
            location: NoteLocation(
                placeName: "",
                city: "",
                country: "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            photos: [],
            dateRangeText: nil,
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
        let state = NoteViewState(
            isLoading: isLoading,
            mode: mode,
            title: current.title ?? "",
            placeTitle: formatHeaderTitle(for: current),
            text: current.text,
            locationTitle: current.location.hasDisplayableValue ? current.location.placeName : "",
            locationSubtitle: current.location.hasDisplayableValue ? (current.location.address ?? "") : "",
            hasLocation: current.location.hasDisplayableValue,
            locationCoordinate: current.location.hasDisplayableValue
                ? LocationCoordinate(latitude: current.location.latitude, longitude: current.location.longitude)
                : nil,
            dateText: formatDateText(for: current),
            isSaveEnabled: isSaveEnabled(for: current),
            isDeleteVisible: originalNote != nil,
            isBookmarked: current.isBookmarked,
            canToggleBookmark: originalNote != nil,
            canSearch: !current.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasUnsavedChanges: hasUnsavedChanges(current),
            photoURLs: current.photoURLs
        )
        onStateChange?(state)
    }

    private func isSaveEnabled(for note: Note) -> Bool {
        let trimmed = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, note.location.hasDisplayableValue else { return false }
        if let original = originalNote {
            return original != note
        }
        return true
    }

    private func hasUnsavedChanges(_ note: Note) -> Bool {
        guard let original = originalNote else {
            return !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || note.location.hasDisplayableValue
        }
        return original != note
    }

    private func formatHeaderTitle(for note: Note) -> String {
        if let override = note.headerTitle, !override.isEmpty {
            return override
        }
        if let city = note.city, let country = note.country {
            return "\(city), \(country)"
        }
        if let country = note.country {
            return country
        }
        return "Untitled"
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
        if let range = note.dateRangeText, !range.isEmpty {
            return range
        }
        return NoteViewModel.dateFormatter.string(from: note.updatedAt)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
