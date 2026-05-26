//
//  CountryPickerViewModel.swift
//  Xplora
//

import Foundation

@MainActor
protocol CountryPickerModuleOutput: AnyObject {
    func countryPickerDidSelect(country: Country)
    func countryPickerDidCancel()
}

@MainActor
final class CountryPickerViewModel {
    var onCountriesLoaded: (([Country]) -> Void)?
    weak var output: CountryPickerModuleOutput?

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
        output?.countryPickerDidSelect(country: country)
    }

    func didTapCancel() {
        output?.countryPickerDidCancel()
    }
}
