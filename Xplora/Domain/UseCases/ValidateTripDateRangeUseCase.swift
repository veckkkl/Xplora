//
//  ValidateTripDateRangeUseCase.swift
//  Xplora
//

import Foundation

enum TripDateValidationError: Error, Equatable {
    case startDateAfterEndDate
    case startDateInFuture
}

protocol ValidateTripDateRangeUseCase {
    func execute(startDate: Date, endDate: Date) -> Result<Void, TripDateValidationError>
}

final class ValidateTripDateRangeUseCaseImpl: ValidateTripDateRangeUseCase {
    private let currentDateProvider: () -> Date

    init(currentDateProvider: @escaping () -> Date = { Date() }) {
        self.currentDateProvider = currentDateProvider
    }

    func execute(startDate: Date, endDate: Date) -> Result<Void, TripDateValidationError> {
        if startDate > currentDateProvider() {
            return .failure(.startDateInFuture)
        }
        if startDate > endDate {
            return .failure(.startDateAfterEndDate)
        }
        return .success(())
    }
}
