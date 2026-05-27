//
//  CreateTripUseCase.swift
//  Xplora
//

import Foundation

protocol CreateTripUseCase {
    func execute(placeCode: String, startDate: Date, endDate: Date) async throws -> Trip
}

final class CreateTripUseCaseImpl: CreateTripUseCase {
    private let tripsRepo: TripsRepo
    private let validateDates: ValidateTripDateRangeUseCase

    init(tripsRepo: TripsRepo, validateDates: ValidateTripDateRangeUseCase) {
        self.tripsRepo = tripsRepo
        self.validateDates = validateDates
    }

    func execute(placeCode: String, startDate: Date, endDate: Date) async throws -> Trip {
        try validateDates.execute(startDate: startDate, endDate: endDate).get()
        let trip = Trip(
            id: UUID(),
            placeCode: placeCode,
            startDate: startDate,
            endDate: endDate,
            notesCount: 0,
            visitedPlaces: []
        )
        try await tripsRepo.save(trip: trip)
        return trip
    }
}
