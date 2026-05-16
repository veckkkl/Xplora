//
//  DeleteTripUseCase.swift
//  Xplora
//

import Foundation

protocol DeleteTripUseCase {
    func execute(tripId: UUID) async throws
}

final class DeleteTripUseCaseImpl: DeleteTripUseCase {
    private let tripsRepo: TripsRepo

    init(tripsRepo: TripsRepo) {
        self.tripsRepo = tripsRepo
    }

    func execute(tripId: UUID) async throws {
        try await tripsRepo.delete(tripId: tripId)
    }
}
