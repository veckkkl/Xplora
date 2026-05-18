//
//  CatalogPlacesRepoImpl.swift
//  Xplora
//

import Foundation

/// Catalog is policy-driven: the source of truth is `CatalogPlacePolicy`, which
/// is compiled into the app. The optional `CountriesAPIClient` is used as an
/// infrastructure refresh / validation step — its result is intersected with
/// the policy and stored in the cache, but never widens the catalog.
///
/// User-visible behaviour:
///   - `getAll()` returns immediately from policy (synchronous semantics).
///   - A background refresh re-validates against the API and updates the cache.
///   - If the API drops an entry that policy still endorses, the entry stays
///     visible (policy wins). If the API returns entries policy doesn't endorse,
///     they are silently filtered out.
final class CatalogPlacesRepoImpl: CatalogPlacesRepo {
    private let api: CountriesAPIClient?
    private let storage: LocalStorageProtocol

    init(api: CountriesAPIClient?, storage: LocalStorageProtocol) {
        self.api = api
        self.storage = storage
    }

    func getAll() async throws -> [CatalogPlace] {
        scheduleBackgroundRefresh()
        return CatalogPlacePolicy.all
    }

    // MARK: - Refresh / cache

    private func scheduleBackgroundRefresh() {
        guard let api else { return }
        let storage = self.storage
        Task.detached(priority: .background) {
            await Self.refresh(using: api, storage: storage)
        }
    }

    private static func refresh(using api: CountriesAPIClient, storage: LocalStorageProtocol) async {
        do {
            let remoteCodes = try await api.fetchCountryCodes()
            let supported = CatalogPlacePolicy.filter(codes: remoteCodes)
            storage.cachedCatalogCodes = supported.map(\.code)
        } catch {
            // Refresh is best-effort; the policy remains the source of truth.
        }
    }
}
