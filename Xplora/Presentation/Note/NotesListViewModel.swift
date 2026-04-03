//
//  NotesListViewModel.swift
//  Xplora
//

import Foundation

struct NotesListItemViewState: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let dateText: String
    let isBookmarked: Bool
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
            return NotesListItemViewState(
                id: note.id,
                title: NotePresentationTitle.displayTitle(from: note.title),
                subtitle: note.text.trimmingCharacters(in: .whitespacesAndNewlines),
                dateText: Self.dateFormatter.string(from: note.updatedAt),
                isBookmarked: note.isBookmarked
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
