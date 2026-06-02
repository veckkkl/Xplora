//
//  NotesListViewModel.swift
//  Xplora
//

import Foundation

struct NotesListItemViewState: Equatable {
    let id: String
    let title: String
    let textPreview: String
    let dateText: String
    let locationChipText: String?
    let isBookmarked: Bool
    let photoURLs: [URL]
}

struct NotesListViewState: Equatable {
    let isLoading: Bool
    let items: [NotesListItemViewState]
    let isEmpty: Bool
}

enum NotesListRoute {
    case addNew
    case open(noteId: String)
}

/// Decides which notes the list screen should display. Defaults to `.all`
/// so the existing entry points (Map → Notes) keep their behaviour.
enum NotesListFilter {
    case all
    /// Show only notes that match the given trip per
    /// `TripNotesCountProviding`'s rule (same logic as the Timeline count).
    case trip(Trip)
}

@MainActor
protocol NotesListViewModelInput: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapAdd()
    func didSelectItem(at index: Int)
    func didDeleteItem(at index: Int)
}

@MainActor
protocol NotesListViewModelOutput: AnyObject {
    var screenTitle: String { get }
    var onStateChange: ((NotesListViewState) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onRoute: ((NotesListRoute) -> Void)? { get set }
}

@MainActor
final class NotesListViewModel: NotesListViewModelInput, NotesListViewModelOutput {
    var onStateChange: ((NotesListViewState) -> Void)?
    var onError: ((String) -> Void)?
    var onRoute: ((NotesListRoute) -> Void)?

    let screenTitle: String

    private let getAllNotesUseCase: GetAllNotesUseCase
    private let tripNotesCountProvider: TripNotesCountProviding
    private let deleteNoteUseCase: DeleteNoteUseCase
    private let filter: NotesListFilter
    private var notes: [Note] = []
    private var isLoading = false

    /// Fires after a note has been removed via swipe-to-delete so the
    /// hosting coordinator can refresh sibling screens (Map markers,
    /// Timeline counts).
    var onNoteDeleted: ((String) -> Void)?

    init(
        getAllNotesUseCase: GetAllNotesUseCase,
        tripNotesCountProvider: TripNotesCountProviding,
        deleteNoteUseCase: DeleteNoteUseCase,
        filter: NotesListFilter = .all,
        screenTitle: String? = nil
    ) {
        self.getAllNotesUseCase = getAllNotesUseCase
        self.tripNotesCountProvider = tripNotesCountProvider
        self.deleteNoteUseCase = deleteNoteUseCase
        self.filter = filter
        self.screenTitle = screenTitle ?? L10n.Notes.List.title
    }

    func viewDidLoad() {
        loadNotes()
    }

    func viewWillAppear() {
        loadNotes()
    }

    func didTapAdd() {
        onRoute?(.addNew)
    }

    func didSelectItem(at index: Int) {
        guard notes.indices.contains(index) else { return }
        onRoute?(.open(noteId: notes[index].id))
    }

    func didDeleteItem(at index: Int) {
        guard notes.indices.contains(index) else { return }
        let note = notes[index]

        // Optimistic UI: drop the note locally first so the row animates out
        // immediately while CoreData and disk cleanup run in the background.
        notes.remove(at: index)
        publish()

        Task { [deleteNoteUseCase, onNoteDeleted, onError] in
            do {
                try await deleteNoteUseCase.execute(noteId: note.id)
                NotesListViewModel.cleanupPhotoFiles(for: note)
                onNoteDeleted?(note.id)
            } catch {
                // Restore the row on failure and surface an error so the user
                // knows the delete didn't take effect.
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.notes.insert(note, at: min(index, self.notes.count))
                    self.publish()
                    onError?(L10n.Notes.List.Error.load)
                }
            }
        }
    }

    private static func cleanupPhotoFiles(for note: Note) {
        for photo in note.photos {
            let url = NotePhotoFileStorage.absoluteURL(for: photo.localPath)
            try? FileManager.default.removeItem(at: url)
        }
        // Drop the per-note directory if it's now empty.
        if let dirURL = try? NotePhotoFileStorage.notesDirectoryURL(noteId: note.id),
           let contents = try? FileManager.default.contentsOfDirectory(atPath: dirURL.path),
           contents.isEmpty {
            try? FileManager.default.removeItem(at: dirURL)
        }
    }

    private func loadNotes() {
        isLoading = true
        publish()

        Task {
            do {
                let fetched = try await getAllNotesUseCase.execute()
                notes = apply(filter: filter, to: fetched)
                isLoading = false
                publish()
            } catch {
                isLoading = false
                notes = []
                publish()
                onError?(L10n.Notes.List.Error.load)
            }
        }
    }

    private func apply(filter: NotesListFilter, to notes: [Note]) -> [Note] {
        switch filter {
        case .all:
            return notes
        case .trip(let trip):
            // Reuse the single source-of-truth matcher so the screen and the
            // Timeline count cell always agree.
            return tripNotesCountProvider.notes(for: trip, in: notes)
        }
    }

    private func publish() {
        let items = notes.map { note in
            let resolvedTitle = NotePresentationTitle.displayTitle(from: note.title)

            let trimmedText = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let textPreview = trimmedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

            let resolvedRange = NoteDateRangeResolver.effectiveRange(
                tripStartDate: note.tripStartDate,
                tripEndDate: note.tripEndDate
            )
            let dateText: String
            if let start = resolvedRange.start, let end = resolvedRange.end {
                dateText = NoteDateRangeFormatter.displayText(startDate: start, endDate: end)
            } else {
                dateText = NoteDateRangeFormatter.displayText(for: note.createdAt)
            }

            let locationTitle = note.location?.placeName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let locationChipText: String? = {
                if !locationTitle.isEmpty { return locationTitle }
                let address = note.location?.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return address.isEmpty ? nil : address
            }()

            return NotesListItemViewState(
                id: note.id,
                title: resolvedTitle,
                textPreview: textPreview,
                dateText: dateText,
                locationChipText: locationChipText,
                isBookmarked: note.isBookmarked,
                photoURLs: note.photoURLs
            )
        }

        onStateChange?(
            NotesListViewState(
                isLoading: isLoading,
                items: items,
                isEmpty: !isLoading && items.isEmpty
            )
        )
    }
}
