//
//  TripsRepoImplTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct TripsRepoImplTests {
    private static let tripsKey = "trips"
    private struct StubError: Error {}

    private func makeSUT() -> (sut: TripsRepoImpl, storage: MockLocalStorage) {
        let storage = MockLocalStorage()
        return (TripsRepoImpl(storage: storage), storage)
    }

    private func makeTrip(placeCode: String = "FR") -> Trip {
        Trip(
            id: UUID(),
            placeCode: placeCode,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            notesCount: 0,
            visitedPlaces: []
        )
    }

    // MARK: - Happy path

    @Test func getAllTrips_whenNothingStored_returnsEmpty() async throws {
        let (sut, _) = makeSUT()
        #expect(try await sut.getAllTrips().isEmpty)
    }

    @Test func save_thenGetAll_returnsTrip() async throws {
        let (sut, _) = makeSUT()
        let trip = makeTrip()
        try await sut.save(trip: trip)
        #expect(try await sut.getAllTrips() == [trip])
    }

    @Test func update_replacesTrip() async throws {
        let (sut, _) = makeSUT()
        let trip = makeTrip(placeCode: "FR")
        try await sut.save(trip: trip)
        let updated = Trip(
            id: trip.id,
            placeCode: "FR",
            startDate: trip.startDate,
            endDate: Date(timeIntervalSince1970: 172_800),
            notesCount: 0,
            visitedPlaces: []
        )
        try await sut.update(trip: updated)
        #expect(try await sut.getTrip(id: trip.id) == updated)
    }

    @Test func delete_removesTrip() async throws {
        let (sut, _) = makeSUT()
        let keep = makeTrip(placeCode: "FR")
        let remove = makeTrip(placeCode: "IT")
        try await sut.save(trip: keep)
        try await sut.save(trip: remove)
        try await sut.delete(tripId: remove.id)
        #expect(try await sut.getAllTrips() == [keep])
    }

    // MARK: - Corrupted data

    @Test func getAllTrips_whenDataCorrupted_throws() async {
        let (sut, storage) = makeSUT()
        storage.store[Self.tripsKey] = Data("not json".utf8)
        await #expect(throws: LocalStorageError.self) { try await sut.getAllTrips() }
    }

    @Test func save_whenExistingDataCorrupted_throwsWithoutOverwriting() async {
        let (sut, storage) = makeSUT()
        let corrupted = Data("not json".utf8)
        storage.store[Self.tripsKey] = corrupted
        await #expect(throws: LocalStorageError.self) { try await sut.save(trip: makeTrip()) }
        #expect(storage.store[Self.tripsKey] == corrupted)
        #expect(storage.saveCallCount == 0)
    }

    @Test func delete_whenExistingDataCorrupted_throwsWithoutOverwriting() async {
        let (sut, storage) = makeSUT()
        let corrupted = Data("not json".utf8)
        storage.store[Self.tripsKey] = corrupted
        await #expect(throws: LocalStorageError.self) { try await sut.delete(tripId: UUID()) }
        #expect(storage.store[Self.tripsKey] == corrupted)
    }

    // MARK: - Write errors

    @Test func save_whenWriteFails_throwsAndKeepsExistingTrips() async throws {
        let (sut, storage) = makeSUT()
        let existing = makeTrip(placeCode: "FR")
        try await sut.save(trip: existing)
        storage.saveError = StubError()

        await #expect(throws: StubError.self) { try await sut.save(trip: makeTrip(placeCode: "IT")) }

        storage.saveError = nil
        #expect(try await sut.getAllTrips() == [existing])
    }
}
