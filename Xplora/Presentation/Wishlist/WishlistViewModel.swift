// WishlistViewModel.swift
// Xplora

import Foundation
import os

/// `empty` means the wishlist was read and has no entries; `error` means it
/// couldn't be read. A failed load never renders as an empty list.
enum WishlistViewState: Equatable {
    case content([WishlistCountry])
    case empty
    case error(String)
}

@MainActor
protocol WishlistViewModelInput: AnyObject {
    func viewDidLoad()
    func didTapAdd()
    func didToggle(id: UUID)
    func didDelete(id: UUID)
    func didSelect(country: WishlistCountry)
    func didConfirmAdd(country: WishlistCountry)
    func didTapRetry()
}

@MainActor
protocol WishlistViewModelOutput: AnyObject {
    var onStateChange: ((WishlistViewState) -> Void)? { get set }
    var onDuplicateError: (() -> Void)? { get set }
    /// A change wasn't saved; the message tells the user so.
    var onOperationError: ((String) -> Void)? { get set }
    var onShowAddCountry: (() -> Void)? { get set }
    var onNeedsConfirmation: ((WishlistAddConfirmation, WishlistCountry) -> Void)? { get set }
}

@MainActor
final class WishlistViewModel: WishlistViewModelInput, WishlistViewModelOutput {
    var onStateChange: ((WishlistViewState) -> Void)?
    var onDuplicateError: (() -> Void)?
    var onOperationError: ((String) -> Void)?
    var onShowAddCountry: (() -> Void)?
    var onNeedsConfirmation: ((WishlistAddConfirmation, WishlistCountry) -> Void)?

    private let getUseCase: GetWishlistCountriesUseCase
    private let addUseCase: AddWishlistCountryUseCase
    private let removeUseCase: RemoveWishlistCountryUseCase
    private let toggleUseCase: ToggleWishlistCountryUseCase
    private var countries: [WishlistCountry] = []

    init(
        getUseCase: GetWishlistCountriesUseCase,
        addUseCase: AddWishlistCountryUseCase,
        removeUseCase: RemoveWishlistCountryUseCase,
        toggleUseCase: ToggleWishlistCountryUseCase
    ) {
        self.getUseCase = getUseCase
        self.addUseCase = addUseCase
        self.removeUseCase = removeUseCase
        self.toggleUseCase = toggleUseCase
    }

    func viewDidLoad() {
        Task { await load() }
    }

    func didTapRetry() {
        Task { await load() }
    }

    func didTapAdd() { onShowAddCountry?() }

    func didToggle(id: UUID) {
        Task { await toggle(id: id) }
    }

    func didDelete(id: UUID) {
        Task { await remove(id: id) }
    }

    func didSelect(country: WishlistCountry) {
        Task { await add(country) }
    }

    func didConfirmAdd(country: WishlistCountry) {
        Task { await add(country, force: true) }
    }

    // MARK: - Operations

    func load() async {
        do {
            countries = sorted(try await getUseCase.execute())
            onStateChange?(countries.isEmpty ? .empty : .content(countries))
        } catch {
            Self.log("load", error)
            onStateChange?(.error(L10n.Wishlist.Error.load))
        }
    }

    func toggle(id: UUID) async {
        do {
            try await toggleUseCase.execute(id: id)
        } catch {
            Self.log("toggle", error)
            onOperationError?(L10n.Wishlist.Error.update)
        }
        // Reload either way so the list shows what is actually stored.
        await load()
    }

    func remove(id: UUID) async {
        do {
            try await removeUseCase.execute(id: id)
        } catch {
            Self.log("remove", error)
            onOperationError?(L10n.Wishlist.Error.remove)
        }
        // On failure this puts back the row the swipe removed optimistically.
        await load()
    }

    func add(_ country: WishlistCountry, force: Bool = false) async {
        let result: WishlistAddResult
        do {
            result = try await addUseCase.execute(country, force: force)
        } catch {
            Self.log("add", error)
            onOperationError?(L10n.Wishlist.Error.add)
            return
        }
        switch result {
        case .added:
            await load()
        case .exactDuplicate:
            onDuplicateError?()
        case .needsConfirmation(let confirmation):
            onNeedsConfirmation?(confirmation, country)
        }
    }

    // MARK: - Private

    private static func log(_ operation: String, _ error: Error) {
        let nsError = error as NSError
        Logger.storage.error(
            "Wishlist \(operation, privacy: .public) failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
        )
    }

    private func sorted(_ list: [WishlistCountry]) -> [WishlistCountry] {
        list.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return $0.addedAt < $1.addedAt
        }
    }
}
