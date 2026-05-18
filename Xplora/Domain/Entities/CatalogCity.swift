//
//  CatalogCity.swift
//  Xplora
//

import Foundation

/// A city / place-of-interest in the Xplora travel catalog, anchored to a
/// `CatalogPlace` via `placeCode`. The display name resolves from `nameKey`
/// when an L10n entry exists, otherwise from `fallbackName`.
///
/// `id` is stable and shaped as `"\(placeCode)-\(normalizedName)"`, so the
/// same city across catalog refreshes hashes to the same value.
struct CatalogCity: Equatable, Hashable, Codable {
    let id: String
    let nameKey: String?
    let fallbackName: String
    let placeCode: String
    let regionName: String?
    let latitude: Double?
    let longitude: Double?

    init(
        id: String,
        nameKey: String? = nil,
        fallbackName: String,
        placeCode: String,
        regionName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.nameKey = nameKey
        self.fallbackName = fallbackName
        self.placeCode = placeCode
        self.regionName = regionName
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Localized name when an `L10n` key is provided and resolves to a real
    /// translation, otherwise the `fallbackName`.
    var displayName: String {
        if let nameKey {
            let resolved = Bundle.main.localizedString(forKey: nameKey, value: nameKey, table: "Localizable")
            if resolved != nameKey { return resolved }
        }
        return fallbackName
    }
}
