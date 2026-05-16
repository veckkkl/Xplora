//
//  UpdateTripDatesUseCase.swift
//  Xplora
//

import Foundation

protocol UpdateTripDatesUseCase {
    func execute(tripId: UUID, startDate: Date, endDate: Date) async throws -> Trip
}

final class UpdateTripDatesUseCaseImpl: UpdateTripDatesUseCase {
    private let tripsRepo: TripsRepo
    private let validateDates: ValidateTripDateRangeUseCase

    init(tripsRepo: TripsRepo, validateDates: ValidateTripDateRangeUseCase) {
        self.tripsRepo = tripsRepo
        self.validateDates = validateDates
    }

    func execute(tripId: UUID, startDate: Date, endDate: Date) async throws -> Trip {
        try validateDates.execute(startDate: startDate, endDate: endDate).get()
        let existing = try await tripsRepo.getTrip(id: tripId)
        let updated = Trip(
            id: existing.id,
            country: existing.country,
            startDate: startDate,
            endDate: endDate,
            notesCount: existing.notesCount,
            visitedPlaces: existing.visitedPlaces
        )
        try await tripsRepo.update(trip: updated)
        return updated
    }
}
