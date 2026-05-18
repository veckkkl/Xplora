//
//  CatalogPlacesRepo.swift
//  Xplora
//

import Foundation

protocol CatalogPlacesRepo {
    /// Returns the full catalog of supported places, sorted by the repository
    /// implementation (callers normally re-sort by localized name within
    /// continent sections).
    func getAll() async throws -> [CatalogPlace]
}
