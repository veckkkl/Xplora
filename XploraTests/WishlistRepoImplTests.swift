//
//  WishlistRepoImplTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct WishlistRepoImplTests {
    private static let wishlistKey = "wishlistCountries"
    private struct StubError: Error {}

    private func makeSUT() -> (sut: WishlistRepoImpl, storage: MockLocalStorage) {
        let storage = MockLocalStorage()
        return (WishlistRepoImpl(storage: storage), storage)
    }

    private func makeCountry(code: String = "FR") -> WishlistCountry {
        WishlistCountry(
            id: UUID(),
            code: code,
            flag: "",
            name: code,
            cityKey: nil,
            note: nil,
            isCompleted: false,
            addedAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Happy path

    @Test func add_thenGetAll_returnsCountry() async throws {
        let (sut, _) = makeSUT()
        let country = makeCountry()
        try await sut.add(country)
        #expect(try await sut.getAll() == [country])
    }

    @Test func toggle_flipsCompletion() async throws {
        let (sut, _) = makeSUT()
        let country = makeCountry()
        try await sut.add(country)
        try await sut.toggle(id: country.id)
        #expect(try await sut.getAll().first?.isCompleted == true)
    }

    @Test func remove_deletesCountry() async throws {
        let (sut, _) = makeSUT()
        let country = makeCountry()
        try await sut.add(country)
        try await sut.remove(id: country.id)
        #expect(try await sut.getAll().isEmpty)
    }

    // MARK: - Corrupted data

    @Test func getAll_whenDataCorrupted_throws() async {
        let (sut, storage) = makeSUT()
        storage.store[Self.wishlistKey] = Data("not json".utf8)
        await #expect(throws: LocalStorageError.self) { try await sut.getAll() }
    }

    @Test func add_whenExistingDataCorrupted_throwsWithoutOverwriting() async {
        let (sut, storage) = makeSUT()
        let corrupted = Data("not json".utf8)
        storage.store[Self.wishlistKey] = corrupted
        await #expect(throws: LocalStorageError.self) { try await sut.add(makeCountry()) }
        #expect(storage.store[Self.wishlistKey] == corrupted)
        #expect(storage.saveCallCount == 0)
    }

    // MARK: - Write errors

    @Test func toggle_whenWriteFails_throwsAndKeepsPreviousState() async throws {
        let (sut, storage) = makeSUT()
        let country = makeCountry()
        try await sut.add(country)
        storage.saveError = StubError()

        await #expect(throws: StubError.self) { try await sut.toggle(id: country.id) }

        #expect(try await sut.getAll() == [country])
    }
}
