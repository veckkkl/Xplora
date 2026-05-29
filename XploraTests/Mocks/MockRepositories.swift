//
//  MockRepositories.swift
//  XploraTests
//

import Foundation
@testable import Xplora

final class MockTripsRepo: TripsRepo {
    var storedTrips: [Trip] = []
    private(set) var deleteAllCallCount = 0

    func getAllTrips() async throws -> [Trip] { storedTrips }
    func getTrip(id: UUID) async throws -> Trip {
        guard let trip = storedTrips.first(where: { $0.id == id }) else { throw TripsRepoError.notFound }
        return trip
    }
    func save(trip: Trip) async throws { storedTrips.append(trip) }
    func update(trip: Trip) async throws {}
    func delete(tripId: UUID) async throws { storedTrips.removeAll { $0.id == tripId } }
    func deleteAll() async throws {
        deleteAllCallCount += 1
        storedTrips = []
    }
}

final class MockWishlistRepo: WishlistRepo {
    var storedCountries: [WishlistCountry] = []
    private(set) var deleteAllCallCount = 0

    func getAll() async throws -> [WishlistCountry] { storedCountries }
    func add(_ country: WishlistCountry) async throws { storedCountries.append(country) }
    func remove(id: UUID) async throws { storedCountries.removeAll { $0.id == id } }
    func toggle(id: UUID) async throws {}
    func deleteAll() async throws {
        deleteAllCallCount += 1
        storedCountries = []
    }
}

final class MockNotesRepo: NotesRepo {
    var storedNotes: [Note] = []
    private(set) var deleteAllCallCount = 0

    func fetchAllNotes() async throws -> [Note] { storedNotes }
    func getNote(id: String) async throws -> Note { throw NoteRepositoryError.notFound }
    func save(note: Note) async throws -> Note { note }
    func delete(noteId: String) async throws {}
    func deleteAll() async throws {
        deleteAllCallCount += 1
        storedNotes = []
    }
}
