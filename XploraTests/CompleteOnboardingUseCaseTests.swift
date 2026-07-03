//
//  CompleteOnboardingUseCaseTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct CompleteOnboardingUseCaseTests {

    private func makeSUT() -> (sut: CompleteOnboardingUseCaseImpl, repo: MockAuthRepository) {
        let repo = MockAuthRepository()
        return (CompleteOnboardingUseCaseImpl(authRepository: repo), repo)
    }

    // MARK: - Delegation

    @Test func execute_callsRepositoryOnce() {
        let (sut, repo) = makeSUT()
        sut.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(repo.completeOnboardingCallCount == 1)
    }

    @Test func execute_forwardsCountryParams() {
        let (sut, repo) = makeSUT()
        sut.execute(name: "Alice", residenceCountryCode: "FR", isWorldCitizen: false)
        #expect(repo.lastName == "Alice")
        #expect(repo.lastResidenceCountryCode == "FR")
        #expect(repo.lastIsWorldCitizen == false)
    }

    @Test func execute_forwardsWorldCitizenParams() {
        let (sut, repo) = makeSUT()
        sut.execute(name: "Bob", residenceCountryCode: nil, isWorldCitizen: true)
        #expect(repo.lastName == "Bob")
        #expect(repo.lastResidenceCountryCode == nil)
        #expect(repo.lastIsWorldCitizen == true)
    }

    @Test func execute_returnsUserFromRepository() {
        let (sut, repo) = makeSUT()
        let expected = AuthUser(
            id: "fixed-id",
            name: "Alice",
            createdAt: .init(timeIntervalSince1970: 0),
            residenceCountryCode: "US",
            isWorldCitizen: false
        )
        repo.stubbedCompletedUser = expected
        let result = sut.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(result == expected)
    }
}
