//
//  TripsRepoImpl.swift
//  Xplora
//

import Foundation

enum TripsRepoError: Error {
    case notFound
}

final class TripsRepoImpl: TripsRepo {
    private let storage: LocalStorageProtocol

    init(storage: LocalStorageProtocol) {
        self.storage = storage
    }

    func getAllTrips() async throws -> [Trip] {
        try storage.loadTrips()
    }

    func getTrip(id: UUID) async throws -> Trip {
        guard let trip = try storage.loadTrips().first(where: { $0.id == id }) else {
            throw TripsRepoError.notFound
        }
        return trip
    }

    func save(trip: Trip) async throws {
        var trips = try storage.loadTrips()
        trips.append(trip)
        try storage.saveTrips(trips)
    }

    func update(trip: Trip) async throws {
        var trips = try storage.loadTrips()
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else {
            throw TripsRepoError.notFound
        }
        trips[index] = trip
        try storage.saveTrips(trips)
    }

    func delete(tripId: UUID) async throws {
        var trips = try storage.loadTrips()
        trips.removeAll { $0.id == tripId }
        try storage.saveTrips(trips)
    }
}
