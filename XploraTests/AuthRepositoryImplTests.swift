//
//  AuthRepositoryImplTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct AuthRepositoryImplTests {

    private func makeSUT() -> (sut: AuthRepositoryImpl, storage: MockLocalStorage) {
        let storage = MockLocalStorage()
        return (AuthRepositoryImpl(storage: storage), storage)
    }

    // MARK: - getCurrentUser

    @Test func getCurrentUser_whenEmpty_returnsNil() {
        let (sut, _) = makeSUT()
        #expect(sut.getCurrentUser() == nil)
    }

    // MARK: - completeOnboarding

    @Test func completeOnboarding_returnsUserWithGivenName() {
        let (sut, _) = makeSUT()
        let user = sut.completeOnboarding(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(user.name == "Alice")
    }

    @Test func completeOnboarding_persistsUser() {
        let (sut, _) = makeSUT()
        let user = sut.completeOnboarding(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(sut.getCurrentUser() == user)
    }

    @Test func completeOnboarding_withCountry_storesCode() {
        let (sut, _) = makeSUT()
        let user = sut.completeOnboarding(name: "Alice", residenceCountryCode: "FR", isWorldCitizen: false)
        #expect(user.residenceCountryCode == "FR")
        #expect(user.isWorldCitizen == false)
    }

    @Test func completeOnboarding_worldCitizen_storesFlag() {
        let (sut, _) = makeSUT()
        let user = sut.completeOnboarding(name: "Bob", residenceCountryCode: nil, isWorldCitizen: true)
        #expect(user.isWorldCitizen == true)
        #expect(user.residenceCountryCode == nil)
    }

    // MARK: - updateName

    @Test func updateName_changesStoredName() {
        let (sut, _) = makeSUT()
        sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        sut.updateName("Bob")
        #expect(sut.getCurrentUser()?.name == "Bob")
    }

    @Test func updateName_preservesId() {
        let (sut, _) = makeSUT()
        let original = sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        sut.updateName("Alice Updated")
        #expect(sut.getCurrentUser()?.id == original.id)
    }

    @Test func updateName_preservesCountryFields() {
        let (sut, _) = makeSUT()
        sut.completeOnboarding(name: "Alice", residenceCountryCode: "DE", isWorldCitizen: false)
        sut.updateName("Alice Updated")
        let updated = sut.getCurrentUser()
        #expect(updated?.residenceCountryCode == "DE")
        #expect(updated?.isWorldCitizen == false)
    }

    @Test func updateName_whenNoUser_doesNothing() {
        let (sut, _) = makeSUT()
        sut.updateName("Ghost")
        #expect(sut.getCurrentUser() == nil)
    }

    // MARK: - logout

    @Test func logout_removesUser() {
        let (sut, _) = makeSUT()
        sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        sut.logout()
        #expect(sut.getCurrentUser() == nil)
    }

    @Test func logout_whenNoUser_doesNotCrash() {
        let (sut, _) = makeSUT()
        sut.logout()
        #expect(sut.getCurrentUser() == nil)
    }
}
