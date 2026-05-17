//
//  GetSuggestedCitiesForPlaceUseCase.swift
//  Xplora
//

import Foundation

protocol GetSuggestedCitiesForPlaceUseCase {
    /// Initial city suggestions shown next to the place input.
    ///
    /// Resolution order:
    /// 1. Curated bundled cities for the place — returned as-is.
    /// 2. Otherwise: capital city fetched from the remote API, wrapped as a
    ///    single-element array.
    /// 3. Otherwise (API unavailable / unknown capital): empty array.
    func execute(placeCode: String) async throws -> [CatalogCity]
}

final class GetSuggestedCitiesForPlaceUseCaseImpl: GetSuggestedCitiesForPlaceUseCase {
    private let repo: CitiesCatalogRepo

    init(repo: CitiesCatalogRepo) {
        self.repo = repo
    }

    func execute(placeCode: String) async throws -> [CatalogCity] {
        let curated = try await repo.curatedCities(forPlaceCode: placeCode)
        if !curated.isEmpty { return curated }

        if let capital = try await repo.capital(forPlaceCode: placeCode) {
            return [capital]
        }
        return []
    }
}
