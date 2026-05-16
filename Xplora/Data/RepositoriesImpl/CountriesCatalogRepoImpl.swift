//
//  CountriesCatalogRepoImpl.swift
//  Xplora
//

import Foundation

final class CountriesCatalogRepoImpl: CountriesCatalogRepo {
    private let api: CountriesAPIClient
    private let storage: LocalStorageProtocol

    init(api: CountriesAPIClient, storage: LocalStorageProtocol) {
        self.api = api
        self.storage = storage
    }

    /// Returns cached countries instantly when available and kicks off a silent
    /// background refresh. When there's no cache, falls back to a synchronous
    /// remote fetch.
    func getAll() async throws -> [CatalogCountry] {
        if let cached = storage.cachedCountryCodes, !cached.isEmpty {
            Task.detached(priority: .background) { [weak self] in
                try? await self?.refreshAndCache()
            }
            return cached.map { CatalogCountry(code: $0) }
        }
        return try await refreshAndCache()
    }

    @discardableResult
    private func refreshAndCache() async throws -> [CatalogCountry] {
        let codes = try await api.fetchCountryCodes()
        let unique = Array(NSOrderedSet(array: codes)) as? [String] ?? codes
        storage.cachedCountryCodes = unique
        return unique.map { CatalogCountry(code: $0) }
    }
}
