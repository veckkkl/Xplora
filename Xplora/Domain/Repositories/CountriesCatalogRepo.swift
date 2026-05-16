//
//  CountriesCatalogRepo.swift
//  Xplora
//

import Foundation

protocol CountriesCatalogRepo {
    /// Returns the full catalog of countries available in the app.
    /// Implementations may serve cached data and refresh in the background.
    func getAll() async throws -> [CatalogCountry]
}
