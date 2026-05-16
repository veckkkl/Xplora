//
//  TripNotesCountProvider.swift
//  Xplora
//

import Foundation

// Abstracts how we count notes per trip.
// Current impl reads the denormalized value stored on Trip itself.
// Replace with a CoreData query once Note gains a tripId foreign key.
protocol TripNotesCountProviding {
    func notesCount(for tripId: UUID) async -> Int
}

final class StoredTripNotesCountProvider: TripNotesCountProviding {
    private let tripsRepo: TripsRepo

    init(tripsRepo: TripsRepo) {
        self.tripsRepo = tripsRepo
    }

    func notesCount(for tripId: UUID) async -> Int {
        guard let trip = try? await tripsRepo.getTrip(id: tripId) else { return 0 }
        return trip.notesCount
    }
}
