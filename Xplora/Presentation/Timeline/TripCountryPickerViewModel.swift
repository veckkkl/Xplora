//
//  TripCountryPickerViewModel.swift
//  Xplora
//

import Foundation

@MainActor
protocol TripCountryPickerModuleOutput: AnyObject {
    func tripCountryPickerDidSelect(country: Country)
    func tripCountryPickerDidCancel()
}

@MainActor
final class TripCountryPickerViewModel {
    var onCountriesLoaded: (([Country]) -> Void)?
    weak var output: TripCountryPickerModuleOutput?

    private let getAllCountries: GetAllCountriesUseCase
    private var allCountries: [Country] = []

    init(getAllCountries: GetAllCountriesUseCase) {
        self.getAllCountries = getAllCountries
    }

    func viewDidLoad() {
        allCountries = getAllCountries.execute()
        onCountriesLoaded?(allCountries)
    }

    func search(query: String) {
        guard !query.isEmpty else {
            onCountriesLoaded?(allCountries)
            return
        }
        let filtered = allCountries.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
        onCountriesLoaded?(filtered)
    }

    func didSelect(country: Country) {
        output?.tripCountryPickerDidSelect(country: country)
    }

    func didTapCancel() {
        output?.tripCountryPickerDidCancel()
    }
}
