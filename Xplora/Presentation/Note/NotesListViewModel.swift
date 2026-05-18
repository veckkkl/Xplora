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

@MainActor
protocol NotesListViewModelInput: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapAdd()
    func didSelectItem(at index: Int)
}

@MainActor
protocol NotesListViewModelOutput: AnyObject {
    var onStateChange: ((NotesListViewState) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onRoute: ((NotesListRoute) -> Void)? { get set }
}

@MainActor
final class NotesListViewModel: NotesListViewModelInput, NotesListViewModelOutput {
    var onStateChange: ((NotesListViewState) -> Void)?
    var onError: ((String) -> Void)?
    var onRoute: ((NotesListRoute) -> Void)?

    private let getAllNotesUseCase: GetAllNotesUseCase
    private var notes: [Note] = []
    private var isLoading = false

    init(getAllNotesUseCase: GetAllNotesUseCase) {
        self.getAllNotesUseCase = getAllNotesUseCase
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

    private func loadNotes() {
        isLoading = true
        publish()

        Task {
            do {
                let fetched = try await getAllNotesUseCase.execute()
                notes = fetched
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
