//
//  ResetUserDataUseCaseTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct ResetUserDataUseCaseTests {

    private func makeSUT() -> (
        sut: ResetUserDataUseCaseImpl,
        auth: MockAuthRepository,
        trips: MockTripsRepo,
        wishlist: MockWishlistRepo,
        notes: MockNotesRepo
    ) {
        let auth = MockAuthRepository()
        let trips = MockTripsRepo()
        let wishlist = MockWishlistRepo()
        let notes = MockNotesRepo()
        let sut = ResetUserDataUseCaseImpl(
            logout: LogoutUseCaseImpl(authRepository: auth),
            tripsRepo: trips,
            wishlistRepo: wishlist,
            notesRepo: notes
        )
        return (sut, auth, trips, wishlist, notes)
    }

    private func seededTrip() -> Trip {
        Trip(
            id: UUID(),
            placeCode: "FR",
            startDate: .init(timeIntervalSince1970: 0),
            endDate: .init(timeIntervalSince1970: 1),
            notesCount: 0,
            visitedPlaces: []
        )
    }

    private func seededCountry() -> WishlistCountry {
        WishlistCountry(
            id: UUID(),
            code: "FR",
            flag: "🇫🇷",
            name: "France",
            cityKey: nil,
            note: nil,
            isCompleted: false,
            addedAt: .init(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Auth

    @Test func execute_logsOutCurrentUser() async {
        let (sut, auth, _, _, _) = makeSUT()
        auth.stubbedUser = AuthUser(
            id: "id", name: "Alice", createdAt: Date(),
            residenceCountryCode: "US", isWorldCitizen: false
        )
        await sut.execute()
        #expect(auth.logoutCallCount == 1)
        #expect(auth.getCurrentUser() == nil)
    }

    // MARK: - Domain data

    @Test func execute_clearsTrips() async {
        let (sut, _, trips, _, _) = makeSUT()
        trips.storedTrips = [seededTrip()]
        await sut.execute()
        #expect(trips.deleteAllCallCount == 1)
        #expect(trips.storedTrips.isEmpty)
    }

    @Test func execute_clearsWishlist() async {
        let (sut, _, _, wishlist, _) = makeSUT()
        wishlist.storedCountries = [seededCountry()]
        await sut.execute()
        #expect(wishlist.deleteAllCallCount == 1)
        #expect(wishlist.storedCountries.isEmpty)
    }

    @Test func execute_clearsNotes() async {
        let (sut, _, _, _, notes) = makeSUT()
        await sut.execute()
        #expect(notes.deleteAllCallCount == 1)
    }

    @Test func execute_clearsEveryStoreInOnePass() async {
        let (sut, auth, trips, wishlist, notes) = makeSUT()
        auth.stubbedUser = AuthUser(
            id: "id", name: "Alice", createdAt: Date(),
            residenceCountryCode: nil, isWorldCitizen: true
        )
        trips.storedTrips = [seededTrip()]
        wishlist.storedCountries = [seededCountry()]
        await sut.execute()
        #expect(auth.getCurrentUser() == nil)
        #expect(trips.deleteAllCallCount == 1)
        #expect(wishlist.deleteAllCallCount == 1)
        #expect(notes.deleteAllCallCount == 1)
    }
}
