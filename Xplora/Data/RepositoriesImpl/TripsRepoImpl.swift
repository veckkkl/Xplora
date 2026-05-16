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
        storage.trips
    }

    func getTrip(id: UUID) async throws -> Trip {
        guard let trip = storage.trips.first(where: { $0.id == id }) else {
            throw TripsRepoError.notFound
        }
        return trip
    }

    func save(trip: Trip) async throws {
        var trips = storage.trips
        trips.append(trip)
        storage.trips = trips
    }

    func update(trip: Trip) async throws {
        var trips = storage.trips
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else {
            throw TripsRepoError.notFound
        }
        trips[index] = trip
        storage.trips = trips
    }

    func delete(tripId: UUID) async throws {
        var trips = storage.trips
        trips.removeAll { $0.id == tripId }
        storage.trips = trips
    }
}
