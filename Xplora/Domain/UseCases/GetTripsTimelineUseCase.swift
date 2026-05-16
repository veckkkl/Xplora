//
//  GetTripsUseCase.swift
//  Xplora
//

import Foundation

protocol GetTripsUseCase {
    func execute() async throws -> [Trip]
}

final class GetTripsUseCaseImpl: GetTripsUseCase {
    private let tripsRepo: TripsRepo

    init(tripsRepo: TripsRepo) {
        self.tripsRepo = tripsRepo
    }

    func execute() async throws -> [Trip] {
        let trips = try await tripsRepo.getAllTrips()
        return trips.sorted { $0.startDate > $1.startDate }
    }
}
