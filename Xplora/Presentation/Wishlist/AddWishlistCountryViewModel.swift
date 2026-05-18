// AddWishlistCountryViewModel.swift
// Xplora

import Foundation

// MARK: - View state

enum AddWishlistCountryLoadingState: Equatable {
    case loading
    case loaded
    case error
}

struct AddWishlistCountryViewState: Equatable {
    let loadingState: AddWishlistCountryLoadingState
    let sections: [CountrySection]
    let selectedPlace: CatalogPlace?
    let cityText: String
    let selectedCity: CatalogCity?
    let citiesForSelectedPlace: [CatalogCity]
    let addButtonEnabled: Bool
    let currentLocationButtonEnabled: Bool
}

// MARK: - Input / Output

@MainActor
protocol AddWishlistCountryViewModelInput: AnyObject {
    func viewDidLoad()
    func didTapRetry()
    func didChangeSearchQuery(_ query: String)
    func didTapPlaceRow(_ place: CatalogPlace)
    func didTapCurrentLocation()
    func didChangeCityText(_ text: String)
    func didSelectCity(_ city: CatalogCity)
    func didTapAdd()
}

@MainActor
protocol AddWishlistCountryViewModelOutput: AnyObject {
    var onStateChange: ((AddWishlistCountryViewState) -> Void)? { get set }
    var onLocationError: ((CurrentLocationError) -> Void)? { get set }
    var onScrollToPlace: ((String) -> Void)? { get set }
    var onSelect: ((WishlistCountry) -> Void)? { get set }
}

// MARK: - ViewModel

@MainActor
final class AddWishlistCountryViewModel: AddWishlistCountryViewModelInput, AddWishlistCountryViewModelOutput {
    var onStateChange: ((AddWishlistCountryViewState) -> Void)?
    var onLocationError: ((CurrentLocationError) -> Void)?
    var onScrollToPlace: ((String) -> Void)?
    var onSelect: ((WishlistCountry) -> Void)?

    private let getCatalogPlacesUseCase: GetCatalogPlacesUseCase
    private let getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase
    private let locationProvider: CurrentCountryProviding

    private var places: [CatalogPlace] = []
    private var sections: [CountrySection] = []
    private var searchQuery = ""
    private var selectedPlace: CatalogPlace?
    private var selectedCity: CatalogCity?
    private var citiesForSelectedPlace: [CatalogCity] = []
    private var cityText = ""
    private var loadingState: AddWishlistCountryLoadingState = .loading

    init(
        getCatalogPlacesUseCase: GetCatalogPlacesUseCase,
        getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase,
        locationProvider: CurrentCountryProviding = CurrentCountryProvider()
    ) {
        self.getCatalogPlacesUseCase = getCatalogPlacesUseCase
        self.getCitiesForPlaceUseCase = getCitiesForPlaceUseCase
        self.locationProvider = locationProvider
    }

    // MARK: - Input

    func viewDidLoad() {
        publish()
        loadCatalog()
    }

    func didTapRetry() {
        loadCatalog()
    }

    func didChangeSearchQuery(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedPlace = nil
        selectedCity = nil
        citiesForSelectedPlace = []
        cityText = ""
        rebuildSections()
        publish()
    }

    func didTapPlaceRow(_ place: CatalogPlace) {
        let isSame = place.code == selectedPlace?.code
        selectedPlace = isSame ? nil : place
        selectedCity = nil
        citiesForSelectedPlace = []
        cityText = ""
        rebuildSections()
        publish()
        if let newPlace = selectedPlace { loadCities(for: newPlace) }
    }

    func didTapCurrentLocation() {
        locationProvider.requestCurrentCountryCode { [weak self] result in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let code):
                    self.selectPlace(byCode: code)
                case .failure(let error):
                    self.onLocationError?(error)
                }
            }
        }
    }

    func didChangeCityText(_ text: String) {
        let hadSelection = selectedCity != nil
        cityText = text
        // Deselect the chip if the user typed away from the chosen suggestion.
        if hadSelection && text != selectedCity?.displayName {
            selectedCity = nil
        }
        publish()
    }

    func didSelectCity(_ city: CatalogCity) {
        selectedCity = city
        cityText = city.displayName
        publish()
    }

    func didTapAdd() {
        guard let place = selectedPlace else { return }
        let trimmed = cityText.trimmingCharacters(in: .whitespacesAndNewlines)

        // If a curated city was chosen, prefer its localization key. Otherwise
        // fall back to the typed text (or the city's fallback name if it has
        // no L10n key) so the WishlistCountry round-trips correctly later.
        let cityKey = selectedCity.flatMap(\.nameKey)
        let note: String? = {
            if let cityKey, !cityKey.isEmpty { return nil }
            if let city = selectedCity { return city.fallbackName }
            return trimmed.isEmpty ? nil : trimmed
        }()

        let country = WishlistCountry(
            id: UUID(),
            code: place.code,
            flag: place.flag,
            name: place.name,
            cityKey: cityKey,
            note: note,
            isCompleted: false,
            addedAt: Date()
        )
        onSelect?(country)
    }

    // MARK: - Private

    private func loadCatalog() {
        loadingState = .loading
        publish()
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.getCatalogPlacesUseCase.execute()
                self.places = result
                self.loadingState = .loaded
                self.rebuildSections()
                self.publish()
            } catch {
                self.loadingState = .error
                self.publish()
            }
        }
    }

    private func loadCities(for place: CatalogPlace) {
        let placeCode = place.code
        Task { [weak self] in
            guard let self else { return }
            let result = (try? await self.getCitiesForPlaceUseCase.execute(placeCode: placeCode)) ?? []
            // Drop the result if the selection moved on while loading.
            guard self.selectedPlace?.code == placeCode else { return }
            self.citiesForSelectedPlace = result
            self.publish()
        }
    }

    /// Selects a place only if the policy recognises the code. Unsupported
    /// codes (e.g. an obscure territory not in the Xplora catalog) surface as
    /// a `.countryNotFound` error rather than picking something silently.
    private func selectPlace(byCode code: String) {
        guard let place = places.first(where: { $0.code == code }) else {
            onLocationError?(.countryNotFound)
            return
        }
        searchQuery = ""
        selectedPlace = place
        selectedCity = nil
        citiesForSelectedPlace = []
        cityText = ""
        rebuildSections()
        publish()
        onScrollToPlace?(code)
        loadCities(for: place)
    }

    private func rebuildSections() {
        let expanded = selectedPlace?.code
        if searchQuery.isEmpty {
            sections = CatalogSectionBuilder.continentSections(from: places, expandedCode: expanded)
        } else if let results = CatalogSectionBuilder.searchResultsSection(
            from: places,
            query: searchQuery,
            expandedCode: expanded
        ) {
            sections = [results]
        } else {
            sections = []
        }
    }

    private func publish() {
        let state = AddWishlistCountryViewState(
            loadingState: loadingState,
            sections: sections,
            selectedPlace: selectedPlace,
            cityText: cityText,
            selectedCity: selectedCity,
            citiesForSelectedPlace: citiesForSelectedPlace,
            addButtonEnabled: selectedPlace != nil,
            currentLocationButtonEnabled: loadingState == .loaded
        )
        onStateChange?(state)
    }
}
