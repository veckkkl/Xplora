//
//  MockUseCases.swift
//  XploraTests
//

import Foundation
@testable import Xplora

final class MockCompleteOnboardingUseCase: CompleteOnboardingUseCase {
    private(set) var callCount = 0
    private(set) var lastName: String?
    private(set) var lastCode: String?
    private(set) var lastIsWorldCitizen: Bool?
    var stubbedError: Error?

    @discardableResult
    func execute(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) throws -> AuthUser {
        callCount += 1
        lastName = name
        lastCode = residenceCountryCode
        lastIsWorldCitizen = isWorldCitizen
        if let stubbedError { throw stubbedError }
        return AuthUser(id: "mock", name: name, createdAt: Date(), residenceCountryCode: residenceCountryCode, isWorldCitizen: isWorldCitizen)
    }
}

final class MockGetCurrentUserUseCase: GetCurrentUserUseCase {
    var stubbedUser: AuthUser?
    var stubbedError: Error?
    func execute() throws -> AuthUser? {
        if let stubbedError { throw stubbedError }
        return stubbedUser
    }
}

final class MockUpdateCurrentUserUseCase: UpdateCurrentUserUseCase {
    private(set) var updatedName: String?
    private(set) var callCount = 0
    private(set) var updatedResidenceCountryCode: String??
    private(set) var residenceCallCount = 0
    var stubbedError: Error?
    func execute(name: String) throws {
        callCount += 1
        if let stubbedError { throw stubbedError }
        updatedName = name
    }
    func execute(residenceCountryCode: String?) throws {
        residenceCallCount += 1
        if let stubbedError { throw stubbedError }
        updatedResidenceCountryCode = residenceCountryCode
    }
}

final class MockGetStatisticsUseCase: GetStatisticsUseCase {
    var stubbedSummary = StatisticsSummary(
        totalUNCount: 0,
        visitedUNCount: 0,
        worldProgressPercent: 0,
        visitedContinentsCount: 0,
        totalContinentsCount: 7,
        continentItems: []
    )
    func execute() async throws -> StatisticsSummary { stubbedSummary }
}

final class MockGetTripsUseCase: GetTripsUseCase {
    var stubbedTrips: [Trip] = []
    func execute() async throws -> [Trip] { stubbedTrips }
}

final class MockDeleteAllUserDataUseCase: DeleteAllUserDataUseCase {
    private(set) var callCount = 0
    var stubbedError: Error?
    func execute() async throws {
        callCount += 1
        if let stubbedError { throw stubbedError }
    }
}
