//
//  OnboardingFlowTests.swift
//  XploraTests
//
//  End-to-end behaviour of the onboarding gate over the real repository +
//  use cases (backed by an in-memory storage). There is no dedicated
//  "onboarding completed" flag: the gate is whether a persisted AuthUser
//  exists, exactly as AppCoordinator.start() decides
//  (`getCurrentUser.execute() != nil ? showMainApp : showOnboarding`).
//

import Testing
@testable import Xplora

struct OnboardingFlowTests {

    private struct SUT {
        let storage: MockLocalStorage
        let getCurrentUser: GetCurrentUserUseCase
        let completeOnboarding: CompleteOnboardingUseCase
        let logout: LogoutUseCase
    }

    private func makeSUT() -> SUT {
        let storage = MockLocalStorage()
        let repo = AuthRepositoryImpl(storage: storage)
        return SUT(
            storage: storage,
            getCurrentUser: GetCurrentUserUseCaseImpl(authRepository: repo),
            completeOnboarding: CompleteOnboardingUseCaseImpl(authRepository: repo),
            logout: LogoutUseCaseImpl(authRepository: repo)
        )
    }

    /// Mirrors AppCoordinator.start(): onboarding is shown when no user exists.
    private func shouldShowOnboarding(_ sut: SUT) -> Bool {
        sut.getCurrentUser.execute() == nil
    }

    // MARK: - First launch

    @Test func firstLaunch_noUser_showsOnboarding() {
        let sut = makeSUT()
        #expect(shouldShowOnboarding(sut) == true)
    }

    // MARK: - After completing onboarding

    @Test func afterCompletion_showsMainApp() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(shouldShowOnboarding(sut) == false)
    }

    @Test func afterCompletion_persistsUserData() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        let user = sut.getCurrentUser.execute()
        #expect(user?.name == "Alice")
        #expect(user?.residenceCountryCode == "US")
        #expect(user?.isWorldCitizen == false)
    }

    @Test func afterCompletion_worldCitizen_persistsFlag() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Bob", residenceCountryCode: nil, isWorldCitizen: true)
        let user = sut.getCurrentUser.execute()
        #expect(user?.isWorldCitizen == true)
        #expect(user?.residenceCountryCode == nil)
    }

    @Test func relaunchAfterCompletion_doesNotShowOnboardingAgain() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        // Simulate subsequent launches reading the same storage.
        #expect(shouldShowOnboarding(sut) == false)
        #expect(shouldShowOnboarding(sut) == false)
    }

    // MARK: - Reset (delete user data)

    @Test func afterReset_showsOnboardingAgain() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        sut.logout.execute()
        #expect(shouldShowOnboarding(sut) == true)
    }

    @Test func afterReset_userDataIsCleared() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        sut.logout.execute()
        #expect(sut.getCurrentUser.execute() == nil)
    }

    @Test func completeOnboardingAgainAfterReset_showsMainApp() {
        let sut = makeSUT()
        sut.completeOnboarding.execute(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        sut.logout.execute()
        sut.completeOnboarding.execute(name: "Carol", residenceCountryCode: "DE", isWorldCitizen: false)
        #expect(shouldShowOnboarding(sut) == false)
        #expect(sut.getCurrentUser.execute()?.name == "Carol")
    }
}
