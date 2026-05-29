//
//  MockAuthRepository.swift
//  XploraTests
//

import Foundation
@testable import Xplora

final class MockAuthRepository: AuthRepository {
    var stubbedUser: AuthUser?

    private(set) var completeOnboardingCallCount = 0
    private(set) var lastName: String?
    private(set) var lastResidenceCountryCode: String?
    private(set) var lastIsWorldCitizen: Bool?

    private(set) var logoutCallCount = 0

    var stubbedCompletedUser: AuthUser?

    func getCurrentUser() -> AuthUser? { stubbedUser }

    @discardableResult
    func completeOnboarding(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser {
        completeOnboardingCallCount += 1
        lastName = name
        lastResidenceCountryCode = residenceCountryCode
        lastIsWorldCitizen = isWorldCitizen
        let user = stubbedCompletedUser ?? AuthUser(
            id: "mock-id",
            name: name,
            createdAt: Date(),
            residenceCountryCode: residenceCountryCode,
            isWorldCitizen: isWorldCitizen
        )
        stubbedUser = user
        return user
    }

    func updateName(_ name: String) {}

    func updateResidenceCountry(_ residenceCountryCode: String?) {}

    func logout() {
        logoutCallCount += 1
        stubbedUser = nil
    }
}
