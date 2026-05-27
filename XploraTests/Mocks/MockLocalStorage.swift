//
//  MockLocalStorage.swift
//  XploraTests
//

import Foundation
@testable import Xplora

final class MockLocalStorage: LocalStorageProtocol {
    private var store: [String: Data] = [:]
    var trips: [Trip] = []
    var settings: UserSettings = .default
    var wishlistCountries: [WishlistCountry] = []
    var cachedCatalogCodes: [String]?

    func save<T: Codable>(_ value: T, forKey key: String) {
        store[key] = try? JSONEncoder().encode(value)
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = store[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func removeValue(forKey key: String) {
        store.removeValue(forKey: key)
    }
}
