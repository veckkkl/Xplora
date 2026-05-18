// WishlistViewModel.swift
// Xplora

import Foundation

struct WishlistViewState: Equatable {
    let items: [WishlistCountry]
    let isEmpty: Bool
}

@MainActor
protocol WishlistViewModelInput: AnyObject {
    func viewDidLoad()
    func didTapAdd()
    func didToggle(id: UUID)
    func didDelete(id: UUID)
    func didSelect(country: WishlistCountry)
    func didConfirmAdd(country: WishlistCountry)
}

@MainActor
protocol WishlistViewModelOutput: AnyObject {
    var onStateChange: ((WishlistViewState) -> Void)? { get set }
    var onDuplicateError: (() -> Void)? { get set }
    var onShowAddCountry: (() -> Void)? { get set }
    var onNeedsConfirmation: ((WishlistAddConfirmation, WishlistCountry) -> Void)? { get set }
}

@MainActor
final class WishlistViewModel: WishlistViewModelInput, WishlistViewModelOutput {
    var onStateChange: ((WishlistViewState) -> Void)?
    var onDuplicateError: (() -> Void)?
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

    func viewDidLoad() { load() }

    func didTapAdd() { onShowAddCountry?() }

    func didToggle(id: UUID) {
        Task {
            try? await toggleUseCase.execute(id: id)
            load()
        }
    }

    func didDelete(id: UUID) {
        Task {
            try? await removeUseCase.execute(id: id)
            load()
        }
    }

    func didSelect(country: WishlistCountry) {
        Task {
            guard let result = try? await addUseCase.execute(country) else { return }
            handle(result: result, country: country)
        }
    }

    func didConfirmAdd(country: WishlistCountry) {
        Task {
            _ = try? await addUseCase.execute(country, force: true)
            load()
        }
    }

    // MARK: - Private

    private func handle(result: WishlistAddResult, country: WishlistCountry) {
        switch result {
        case .added:
            load()
        case .exactDuplicate:
            onDuplicateError?()
        case .needsConfirmation(let confirmation):
            onNeedsConfirmation?(confirmation, country)
        }
    }

    private func load() {
        Task {
            let fetched = (try? await getUseCase.execute()) ?? []
            countries = sorted(fetched)
            publish()
        }
    }

    private func sorted(_ list: [WishlistCountry]) -> [WishlistCountry] {
        list.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return $0.addedAt < $1.addedAt
        }
    }

    private func publish() {
        onStateChange?(WishlistViewState(items: countries, isEmpty: countries.isEmpty))
    }
}
