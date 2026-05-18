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

    @discardableResult
    func execute(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser {
        callCount += 1
        lastName = name
        lastCode = residenceCountryCode
        lastIsWorldCitizen = isWorldCitizen
        return AuthUser(id: "mock", name: name, createdAt: Date(), residenceCountryCode: residenceCountryCode, isWorldCitizen: isWorldCitizen)
    }
}

final class MockGetCurrentUserUseCase: GetCurrentUserUseCase {
    var stubbedUser: AuthUser?
    func execute() -> AuthUser? { stubbedUser }
}

final class MockUpdateCurrentUserUseCase: UpdateCurrentUserUseCase {
    private(set) var updatedName: String?
    private(set) var callCount = 0
    func execute(name: String) {
        callCount += 1
        updatedName = name
    }
}
