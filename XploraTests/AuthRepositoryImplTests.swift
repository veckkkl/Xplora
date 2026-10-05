//
//  AuthRepositoryImplTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct AuthRepositoryImplTests {

    private func makeSUT() -> (sut: AuthRepositoryImpl, storage: MockLocalStorage) {
        let storage = MockLocalStorage()
        return (AuthRepositoryImpl(storage: storage), storage)
    }

    // MARK: - getCurrentUser

    @Test func getCurrentUser_whenEmpty_returnsNil() throws {
        let (sut, _) = makeSUT()
        #expect(try sut.getCurrentUser() == nil)
    }

    // MARK: - completeOnboarding

    @Test func completeOnboarding_returnsUserWithGivenName() throws {
        let (sut, _) = makeSUT()
        let user = try sut.completeOnboarding(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(user.name == "Alice")
    }

    @Test func completeOnboarding_persistsUser() throws {
        let (sut, _) = makeSUT()
        let user = try sut.completeOnboarding(name: "Alice", residenceCountryCode: "US", isWorldCitizen: false)
        #expect(try sut.getCurrentUser() == user)
    }

    @Test func completeOnboarding_withCountry_storesCode() throws {
        let (sut, _) = makeSUT()
        let user = try sut.completeOnboarding(name: "Alice", residenceCountryCode: "FR", isWorldCitizen: false)
        #expect(user.residenceCountryCode == "FR")
        #expect(user.isWorldCitizen == false)
    }

    @Test func completeOnboarding_worldCitizen_storesFlag() throws {
        let (sut, _) = makeSUT()
        let user = try sut.completeOnboarding(name: "Bob", residenceCountryCode: nil, isWorldCitizen: true)
        #expect(user.isWorldCitizen == true)
        #expect(user.residenceCountryCode == nil)
    }

    // MARK: - updateName

    @Test func updateName_changesStoredName() throws {
        let (sut, _) = makeSUT()
        try sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        try sut.updateName("Bob")
        #expect(try sut.getCurrentUser()?.name == "Bob")
    }

    @Test func updateName_preservesId() throws {
        let (sut, _) = makeSUT()
        let original = try sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        try sut.updateName("Alice Updated")
        #expect(try sut.getCurrentUser()?.id == original.id)
    }

    @Test func updateName_preservesCountryFields() throws {
        let (sut, _) = makeSUT()
        try sut.completeOnboarding(name: "Alice", residenceCountryCode: "DE", isWorldCitizen: false)
        try sut.updateName("Alice Updated")
        let updated = try sut.getCurrentUser()
        #expect(updated?.residenceCountryCode == "DE")
        #expect(updated?.isWorldCitizen == false)
    }

    @Test func updateName_whenNoUser_doesNothing() throws {
        let (sut, _) = makeSUT()
        try sut.updateName("Ghost")
        #expect(try sut.getCurrentUser() == nil)
    }

    // MARK: - logout

    @Test func logout_removesUser() throws {
        let (sut, _) = makeSUT()
        try sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        sut.logout()
        #expect(try sut.getCurrentUser() == nil)
    }

    @Test func logout_whenNoUser_doesNotCrash() throws {
        let (sut, _) = makeSUT()
        sut.logout()
        #expect(try sut.getCurrentUser() == nil)
    }

    // MARK: - Storage errors

    private static let userKey = "auth.current_user"
    private struct StubError: Error {}

    @Test func getCurrentUser_whenStoredDataCorrupted_throws() {
        let (sut, storage) = makeSUT()
        storage.store[Self.userKey] = Data("not json".utf8)
        #expect(throws: LocalStorageError.self) { try sut.getCurrentUser() }
    }

    @Test func updateName_whenStoredDataCorrupted_throwsAndKeepsData() {
        let (sut, storage) = makeSUT()
        let corrupted = Data("{\"id\":1}".utf8)
        storage.store[Self.userKey] = corrupted
        #expect(throws: LocalStorageError.self) { try sut.updateName("Bob") }
        #expect(storage.store[Self.userKey] == corrupted)
        #expect(storage.saveCallCount == 0)
    }

    @Test func updateName_whenSaveFails_throwsAndKeepsPreviousUser() throws {
        let (sut, storage) = makeSUT()
        let original = try sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        storage.saveError = StubError()
        #expect(throws: StubError.self) { try sut.updateName("Bob") }
        #expect(try sut.getCurrentUser() == original)
    }

    @Test func completeOnboarding_whenSaveFails_throws() {
        let (sut, storage) = makeSUT()
        storage.saveError = StubError()
        #expect(throws: StubError.self) {
            try sut.completeOnboarding(name: "Alice", residenceCountryCode: nil, isWorldCitizen: false)
        }
        #expect(storage.store[Self.userKey] == nil)
    }
}
