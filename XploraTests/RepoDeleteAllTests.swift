//
//  RepoDeleteAllTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct RepoDeleteAllTests {

    @Test func tripsRepo_deleteAll_clearsStorage() async throws {
        let storage = MockLocalStorage()
        storage.trips = [
            Trip(
                id: UUID(), placeCode: "FR",
                startDate: .init(timeIntervalSince1970: 0),
                endDate: .init(timeIntervalSince1970: 1),
                notesCount: 0, visitedPlaces: []
            )
        ]
        let sut = TripsRepoImpl(storage: storage)
        try await sut.deleteAll()
        #expect(storage.trips.isEmpty)
    }

    @Test func wishlistRepo_deleteAll_clearsStorage() async throws {
        let storage = MockLocalStorage()
        storage.wishlistCountries = [
            WishlistCountry(
                id: UUID(), code: "FR", flag: "🇫🇷", name: "France",
                cityKey: nil, note: nil, isCompleted: false,
                addedAt: .init(timeIntervalSince1970: 0)
            )
        ]
        let sut = WishlistRepoImpl(storage: storage)
        try await sut.deleteAll()
        #expect(storage.wishlistCountries.isEmpty)
    }
}
