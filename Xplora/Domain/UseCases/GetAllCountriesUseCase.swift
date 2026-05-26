//
//  GetAllCountriesUseCase.swift
//  Xplora
//

import Foundation

protocol GetAllCountriesUseCase {
    func execute() -> [Country]
}

final class GetAllCountriesUseCaseImpl: GetAllCountriesUseCase {
    func execute() -> [Country] {
        CountryCatalog.allCountries()
    }
}
