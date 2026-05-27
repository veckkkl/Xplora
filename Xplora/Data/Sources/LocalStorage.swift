//
//  LocalStorage.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//
import Foundation

final class LocalStorage: LocalStorageProtocol {

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let trips = "trips"
        static let settings = "settings"
        static let wishlistCountries = "wishlistCountries"
        static let cachedCatalogCodes = "cachedCatalogCodes"
    }

    init() {}

    func save<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }

    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    var trips: [Trip] {
        get { load([Trip].self, forKey: Keys.trips) ?? [] }
        set { save(newValue, forKey: Keys.trips) }
    }

    var settings: UserSettings {
        get { load(UserSettings.self, forKey: Keys.settings) ?? .default }
        set { save(newValue, forKey: Keys.settings) }
    }

    var wishlistCountries: [WishlistCountry] {
        get { load([WishlistCountry].self, forKey: Keys.wishlistCountries) ?? [] }
        set { save(newValue, forKey: Keys.wishlistCountries) }
    }

    var cachedCatalogCodes: [String]? {
        get { load([String].self, forKey: Keys.cachedCatalogCodes) }
        set {
            if let newValue {
                save(newValue, forKey: Keys.cachedCatalogCodes)
            } else {
                removeValue(forKey: Keys.cachedCatalogCodes)
            }
        }
    }
}
