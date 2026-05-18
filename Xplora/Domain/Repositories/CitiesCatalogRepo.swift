//
//  CitiesCatalogRepo.swift
//  Xplora
//

import Foundation

protocol CitiesCatalogRepo {
    /// Returns the curated cities for a given place. Empty when the place is
    /// not part of the supported catalog or has no curated cities yet.
    func cities(forPlaceCode code: String) async throws -> [CatalogCity]

    /// Global search across the catalog. Matches `displayName` and
    /// `fallbackName` case- and diacritic-insensitively. Results are
    /// deduplicated by `id` and confined to supported places.
    func search(query: String) async throws -> [CatalogCity]
}
