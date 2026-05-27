//
//  TripCountryPickerViewModel.swift
//  Xplora
//

import Foundation

@MainActor
protocol TripCountryPickerModuleOutput: AnyObject {
    func tripCountryPickerDidSelect(place: CatalogPlace)
    func tripCountryPickerDidCancel()
}

enum TripCountryPickerLoadingState: Equatable {
    case loading
    case loaded
    case error
}

struct TripCountryPickerViewState: Equatable {
    let loadingState: TripCountryPickerLoadingState
    let sections: [CountrySection]
}

@MainActor
final class TripCountryPickerViewModel {
    var onStateChange: ((TripCountryPickerViewState) -> Void)?
    weak var output: TripCountryPickerModuleOutput?

    private let getCatalogPlaces: GetCatalogPlacesUseCase
    private var allPlaces: [CatalogPlace] = []
    private var searchQuery = ""
    private var loadingState: TripCountryPickerLoadingState = .loading

    init(getCatalogPlaces: GetCatalogPlacesUseCase) {
        self.getCatalogPlaces = getCatalogPlaces
    }

    func viewDidLoad() {
        publish(sections: [])
        loadCatalog()
    }

    func didTapRetry() {
        loadCatalog()
    }

    func search(query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        publish(sections: buildSections())
    }

    func didSelect(place: CatalogPlace) {
        output?.tripCountryPickerDidSelect(place: place)
    }

    func didTapCancel() {
        output?.tripCountryPickerDidCancel()
    }

    // MARK: - Private

    private func loadCatalog() {
        loadingState = .loading
        publish(sections: [])
        Task { [weak self] in
            guard let self else { return }
            do {
                let places = try await self.getCatalogPlaces.execute()
                self.allPlaces = places
                self.loadingState = .loaded
                self.publish(sections: self.buildSections())
            } catch {
                self.loadingState = .error
                self.publish(sections: [])
            }
        }
    }

    private func buildSections() -> [CountrySection] {
        if searchQuery.isEmpty {
            return CatalogSectionBuilder.continentSections(from: allPlaces)
        }
        if let results = CatalogSectionBuilder.searchResultsSection(
            from: allPlaces,
            query: searchQuery
        ) {
            return [results]
        }
        return []
    }

    private func publish(sections: [CountrySection]) {
        onStateChange?(TripCountryPickerViewState(
            loadingState: loadingState,
            sections: sections
        ))
    }
}
