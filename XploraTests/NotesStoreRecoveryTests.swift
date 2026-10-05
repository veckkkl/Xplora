//
//  NotesStoreRecoveryTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

private final class NoopDeleteNoteUseCase: DeleteNoteUseCase {
    func execute(noteId: String) async throws {}
}

private final class NoopNotePhotoStore: NotePhotoStore, @unchecked Sendable {
    func savePhoto(_ jpegData: Data, noteId: String) async throws -> String { "" }
    func loadPhotoData(at localPath: String) async throws -> Data { Data() }
    func contentHash(ofPhotoAt localPath: String) async throws -> String { "" }
    func deletePhoto(at localPath: String) async throws {}
    func deleteAllPhotos(noteId: String) async throws {}
    func deleteAllNotePhotos() async throws {}
}

@MainActor
struct NotesStoreRecoveryTests {

    private func makeBrokenStoreURL() throws -> (directory: URL, storeURL: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotesStoreRecovery-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("Broken.sqlite")
        try Data(repeating: 0x42, count: 4096).write(to: storeURL)
        return (directory, storeURL)
    }

    private func makeListViewModel(stack: CoreDataStack) -> NotesListViewModel {
        NotesListViewModel(
            getAllNotesUseCase: GetAllNotesUseCaseImpl(notesRepo: NotesRepoImpl(coreDataStack: stack)),
            tripNotesCountProvider: NoteLocationTripNotesCountProvider(),
            deleteNoteUseCase: NoopDeleteNoteUseCase(),
            photoStore: NoopNotePhotoStore()
        )
    }

    @Test func workingStore_showsNormalNotesFlow() async throws {
        let stack = CoreDataStack(inMemory: true)
        let now = Date()
        _ = try await NotesRepoImpl(coreDataStack: stack).save(note: Note(
            id: "n1", title: "T", text: "", createdAt: now, updatedAt: now,
            tripStartDate: nil, tripEndDate: nil, isBookmarked: false,
            location: nil, photos: [], headerTitle: nil
        ))
        let sut = makeListViewModel(stack: stack)
        var state: NotesListViewState?
        sut.onStateChange = { state = $0 }

        await sut.performLoad()

        #expect(state?.items.map(\.id) == ["n1"])
        #expect(state?.errorMessage == nil)
        #expect(state?.isEmpty == false)
    }

    @Test func workingEmptyStore_showsEmptyState() async {
        let sut = makeListViewModel(stack: CoreDataStack(inMemory: true))
        var state: NotesListViewState?
        sut.onStateChange = { state = $0 }

        await sut.performLoad()

        #expect(state?.isEmpty == true)
        #expect(state?.errorMessage == nil)
    }

    @Test func unavailableStore_showsErrorNotEmptyList() async throws {
        let (directory, storeURL) = try makeBrokenStoreURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let sut = makeListViewModel(stack: CoreDataStack(storeURL: storeURL))
        var state: NotesListViewState?
        sut.onStateChange = { state = $0 }

        await sut.performLoad()

        #expect(state?.errorMessage == L10n.Notes.List.Error.load)
        #expect(state?.isEmpty == false)
        #expect(state?.items.isEmpty == true)
    }

    @Test func retry_afterStoreBecomesReadable_loads() async throws {
        let (directory, storeURL) = try makeBrokenStoreURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let stack = CoreDataStack(storeURL: storeURL)
        #expect(!stack.isStoreLoaded)

        // Simulate the transient cause going away (never done by the app itself).
        try FileManager.default.removeItem(at: storeURL)

        #expect(throws: Never.self) { try stack.loadedViewContext() }
        #expect(stack.isStoreLoaded)
    }

    @Test func timeline_whenNotesStoreUnavailable_stillShowsTrips() async throws {
        let (directory, storeURL) = try makeBrokenStoreURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let trips = MockGetTripsUseCase()
        trips.stubbedTrips = [Trip(
            id: UUID(), placeCode: "FR",
            startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 86_400),
            notesCount: 0, visitedPlaces: []
        )]
        let sut = TimelineViewModel(
            getTripsUseCase: trips,
            getCatalogPlaces: StubCatalogPlaces(),
            getAllNotesUseCase: GetAllNotesUseCaseImpl(
                notesRepo: NotesRepoImpl(coreDataStack: CoreDataStack(storeURL: storeURL))
            ),
            deleteTripUseCase: NoopDeleteTripUseCase(),
            tripNotesCountProvider: NoteLocationTripNotesCountProvider()
        )
        var state: TimelineViewState?
        sut.onStateChange = { state = $0 }

        await sut.performLoad()

        #expect(state?.sections.flatMap(\.items).count == 1)
        #expect(state?.errorMessage == nil)
    }
}

@MainActor
struct TimelineErrorStateTests {

    private final class FailingTripsUseCase: GetTripsUseCase {
        func execute() async throws -> [Trip] { throw CocoaError(.coderReadCorrupt) }
    }

    private final class EmptyNotesUseCase: GetAllNotesUseCase {
        func execute() async throws -> [Note] { [] }
    }

    private func makeSUT(getTrips: GetTripsUseCase) -> TimelineViewModel {
        TimelineViewModel(
            getTripsUseCase: getTrips,
            getCatalogPlaces: StubCatalogPlaces(),
            getAllNotesUseCase: EmptyNotesUseCase(),
            deleteTripUseCase: NoopDeleteTripUseCase(),
            tripNotesCountProvider: NoteLocationTripNotesCountProvider()
        )
    }

    @Test func noTrips_showsEmptyState() async {
        let sut = makeSUT(getTrips: MockGetTripsUseCase())
        var state: TimelineViewState?
        sut.onStateChange = { state = $0 }

        await sut.performLoad()

        #expect(state?.isEmpty == true)
        #expect(state?.errorMessage == nil)
    }

    @Test func tripsLoadFails_showsErrorNotEmpty() async {
        let sut = makeSUT(getTrips: FailingTripsUseCase())
        var state: TimelineViewState?
        sut.onStateChange = { state = $0 }

        await sut.performLoad()

        #expect(state?.errorMessage == L10n.Timeline.Error.load)
        #expect(state?.isEmpty == false)
    }
}

private final class StubCatalogPlaces: GetCatalogPlacesUseCase {
    func execute() async throws -> [CatalogPlace] { [CatalogPlace(code: "FR", status: .un)] }
}

private final class NoopDeleteTripUseCase: DeleteTripUseCase {
    func execute(tripId: UUID) async throws {}
}
