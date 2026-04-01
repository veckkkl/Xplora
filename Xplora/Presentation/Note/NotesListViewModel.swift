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
                onError?("Couldn't load notes. Please try again.")
            }
        }
    }

    private func publish() {
        let items = notes.map { note in
            NotesListItemViewState(
                id: note.id,
                title: NotePresentationFactory.title(for: note),
                textPreview: NotePresentationFactory.textPreview(for: note),
                dateText: NotePresentationFactory.formattedDateRange(for: note),
                locationChipText: NotePresentationFactory.locationChipText(for: note),
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
