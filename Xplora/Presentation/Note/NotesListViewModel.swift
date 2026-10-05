//
//  NotesListViewModel.swift
//  Xplora
//

import Foundation
import os

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
    /// True only when notes were loaded and there are none.
    let isEmpty: Bool
    /// Set when notes couldn't be loaded (e.g. the store is unavailable);
    /// shown instead of the empty state.
    var errorMessage: String? = nil
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
    func didTapRetry()
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
    private let photoStore: NotePhotoStore
    private let filter: NotesListFilter
    private var notes: [Note] = []
    private var isLoading = false
    private var loadErrorMessage: String?

    /// Fires after a note has been removed via swipe-to-delete so the
    /// hosting coordinator can refresh sibling screens (Map markers,
    /// Timeline counts).
    var onNoteDeleted: ((String) -> Void)?

    init(
        getAllNotesUseCase: GetAllNotesUseCase,
        tripNotesCountProvider: TripNotesCountProviding,
        deleteNoteUseCase: DeleteNoteUseCase,
        photoStore: NotePhotoStore,
        filter: NotesListFilter = .all,
        screenTitle: String? = nil
    ) {
        self.getAllNotesUseCase = getAllNotesUseCase
        self.tripNotesCountProvider = tripNotesCountProvider
        self.deleteNoteUseCase = deleteNoteUseCase
        self.photoStore = photoStore
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

    func didTapRetry() {
        loadNotes()
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

        Task { [deleteNoteUseCase, photoStore, onNoteDeleted, onError] in
            do {
                try await deleteNoteUseCase.execute(noteId: note.id)
                // Best-effort: a leftover file doesn't affect the deleted
                // note, and failures are logged by the store.
                try? await photoStore.deleteAllPhotos(noteId: note.id)
                onNoteDeleted?(note.id)
            } catch {
                // Restore the row on failure and surface an error so the user
                // knows the delete didn't take effect.
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.notes.insert(note, at: min(index, self.notes.count))
                    self.publish()
                    onError?(L10n.Notes.List.Error.delete)
                }
            }
        }
    }

    private func loadNotes() {
        isLoading = true
        publish()

        Task {
            await performLoad()
        }
    }

    /// Internal so tests can await a load.
    func performLoad() async {
        do {
            let fetched = try await getAllNotesUseCase.execute()
            notes = apply(filter: filter, to: fetched)
            loadErrorMessage = nil
        } catch {
            let nsError = error as NSError
            Logger.storage.error(
                "Notes list load failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            notes = []
            loadErrorMessage = L10n.Notes.List.Error.load
        }
        isLoading = false
        publish()
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

        let errorMessage = isLoading ? nil : loadErrorMessage
        onStateChange?(
            NotesListViewState(
                isLoading: isLoading,
                items: items,
                isEmpty: !isLoading && errorMessage == nil && items.isEmpty,
                errorMessage: errorMessage
            )
        )
    }
}
