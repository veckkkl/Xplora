//
//  WishlistViewModelTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

@MainActor
struct WishlistViewModelTests {

    private struct SUT {
        let viewModel: WishlistViewModel
        let storage: MockLocalStorage
        let repo: WishlistRepoImpl
    }

    private func makeSUT() -> SUT {
        let storage = MockLocalStorage()
        let repo = WishlistRepoImpl(storage: storage)
        let viewModel = WishlistViewModel(
            getUseCase: GetWishlistCountriesUseCaseImpl(repo: repo),
            addUseCase: AddWishlistCountryUseCaseImpl(repo: repo),
            removeUseCase: RemoveWishlistCountryUseCaseImpl(repo: repo),
            toggleUseCase: ToggleWishlistCountryUseCaseImpl(repo: repo)
        )
        return SUT(viewModel: viewModel, storage: storage, repo: repo)
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

    // MARK: - Load

    @Test func load_emptyWishlist_publishesEmpty() async {
        let sut = makeSUT()
        var states: [WishlistViewState] = []
        sut.viewModel.onStateChange = { states.append($0) }

        await sut.viewModel.load()

        #expect(states == [.empty])
    }

    @Test func load_unreadableWishlist_publishesErrorNotEmpty() async {
        let sut = makeSUT()
        sut.storage.store["wishlistCountries"] = Data("corrupted".utf8)
        var states: [WishlistViewState] = []
        sut.viewModel.onStateChange = { states.append($0) }

        await sut.viewModel.load()

        #expect(states == [.error(L10n.Wishlist.Error.load)])
    }

    @Test func load_withEntries_publishesContent() async throws {
        let sut = makeSUT()
        let country = makeCountry()
        try await sut.repo.add(country)
        var states: [WishlistViewState] = []
        sut.viewModel.onStateChange = { states.append($0) }

        await sut.viewModel.load()

        #expect(states == [.content([country])])
    }

    // MARK: - Operations

    @Test func add_whenSaveFails_reportsErrorAndKeepsList() async {
        let sut = makeSUT()
        sut.storage.saveError = CocoaError(.fileWriteUnknown)
        var states: [WishlistViewState] = []
        var operationError: String?
        sut.viewModel.onStateChange = { states.append($0) }
        sut.viewModel.onOperationError = { operationError = $0 }

        await sut.viewModel.add(makeCountry())

        #expect(operationError == L10n.Wishlist.Error.add)
        #expect(states.isEmpty)
    }

    @Test func remove_whenSaveFails_reportsErrorAndKeepsEntry() async throws {
        let sut = makeSUT()
        let country = makeCountry()
        try await sut.repo.add(country)
        sut.storage.saveError = CocoaError(.fileWriteUnknown)
        var states: [WishlistViewState] = []
        var operationError: String?
        sut.viewModel.onStateChange = { states.append($0) }
        sut.viewModel.onOperationError = { operationError = $0 }

        await sut.viewModel.remove(id: country.id)

        #expect(operationError == L10n.Wishlist.Error.remove)
        // The row the swipe removed comes back.
        #expect(states.last == .content([country]))
    }

    @Test func toggle_whenSaveFails_reportsErrorAndKeepsState() async throws {
        let sut = makeSUT()
        let country = makeCountry()
        try await sut.repo.add(country)
        sut.storage.saveError = CocoaError(.fileWriteUnknown)
        var states: [WishlistViewState] = []
        var operationError: String?
        sut.viewModel.onStateChange = { states.append($0) }
        sut.viewModel.onOperationError = { operationError = $0 }

        await sut.viewModel.toggle(id: country.id)

        #expect(operationError == L10n.Wishlist.Error.update)
        #expect(states.last == .content([country]))
    }

    @Test func toggle_success_publishesUpdatedEntry() async throws {
        let sut = makeSUT()
        let country = makeCountry()
        try await sut.repo.add(country)
        var states: [WishlistViewState] = []
        var operationError: String?
        sut.viewModel.onStateChange = { states.append($0) }
        sut.viewModel.onOperationError = { operationError = $0 }

        await sut.viewModel.toggle(id: country.id)

        var toggled = country
        toggled.isCompleted = true
        #expect(operationError == nil)
        #expect(states.last == .content([toggled]))
    }
}
