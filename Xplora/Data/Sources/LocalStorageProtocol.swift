//
//  LocalStorageProtocol.swift
//  Xplora
//
//  Created by valentina balde on 11/19/25.
//

import Foundation

enum LocalStorageError: Error {
    /// The value could not be encoded; nothing was written.
    case encodingFailed(key: String, underlying: Error)
    /// Data exists under the key but cannot be decoded into the requested type.
    /// The stored data is left untouched.
    case decodingFailed(key: String, underlying: Error)
}

protocol LocalStorageProtocol: AnyObject {
    /// Encodes and stores `value`. Throws `LocalStorageError.encodingFailed`
    /// without touching the previously stored value.
    func save<T: Codable>(_ value: T, forKey key: String) throws

    /// Returns `nil` only when nothing is stored under `key`.
    /// Throws `LocalStorageError.decodingFailed` when stored data is unreadable.
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?

    func removeValue(forKey key: String)
}

// MARK: - Typed accessors

private enum LocalStorageKeys {
    static let trips = "trips"
    static let settings = "settings"
    static let wishlistCountries = "wishlistCountries"
    static let cachedCatalogCodes = "cachedCatalogCodes"
}

extension LocalStorageProtocol {
    func loadTrips() throws -> [Trip] {
        try load([Trip].self, forKey: LocalStorageKeys.trips) ?? []
    }

    func saveTrips(_ trips: [Trip]) throws {
        try save(trips, forKey: LocalStorageKeys.trips)
    }

    func removeTrips() {
        removeValue(forKey: LocalStorageKeys.trips)
    }

    func loadSettings() throws -> UserSettings {
        try load(UserSettings.self, forKey: LocalStorageKeys.settings) ?? .default
    }

    func saveSettings(_ settings: UserSettings) throws {
        try save(settings, forKey: LocalStorageKeys.settings)
    }

    func removeSettings() {
        removeValue(forKey: LocalStorageKeys.settings)
    }

    func loadWishlistCountries() throws -> [WishlistCountry] {
        try load([WishlistCountry].self, forKey: LocalStorageKeys.wishlistCountries) ?? []
    }

    func saveWishlistCountries(_ countries: [WishlistCountry]) throws {
        try save(countries, forKey: LocalStorageKeys.wishlistCountries)
    }

    func removeWishlistCountries() {
        removeValue(forKey: LocalStorageKeys.wishlistCountries)
    }

    func loadCachedCatalogCodes() throws -> [String]? {
        try load([String].self, forKey: LocalStorageKeys.cachedCatalogCodes)
    }

    func saveCachedCatalogCodes(_ codes: [String]?) throws {
        if let codes {
            try save(codes, forKey: LocalStorageKeys.cachedCatalogCodes)
        } else {
            removeValue(forKey: LocalStorageKeys.cachedCatalogCodes)
        }
    }
}
