//
//  CitiesCatalogRepo.swift
//  Xplora
//

import Foundation

protocol CitiesCatalogRepo {
    /// Curated bundled cities for a given place (popular destinations).
    /// Empty when the place is unsupported or has no curated entries.
    func curatedCities(forPlaceCode code: String) async throws -> [CatalogCity]

    /// Capital city sourced from the remote API. `nil` when the place is
    /// unsupported, the API has no record, or the call failed. Cached
    /// in-memory per place so repeat lookups are free.
    func capital(forPlaceCode code: String) async throws -> CatalogCity?

    /// Full list of cities for a place sourced from the remote API. Used
    /// for autocomplete only. Empty when unsupported / API failure.
    /// Cached in-memory per place.
    func allCities(forPlaceCode code: String) async throws -> [CatalogCity]

    /// Global search across the curated catalog. Matches `displayName`
    /// and `fallbackName` case- and diacritic-insensitively. Results are
    /// deduplicated by `id` and confined to supported places.
    func search(query: String) async throws -> [CatalogCity]
}
