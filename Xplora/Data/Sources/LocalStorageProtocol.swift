//
//  LocalStorageProtocol.swift
//  Xplora
//
//  Created by valentina balde on 11/19/25.
//

// LocalStorage.swift

import Foundation

protocol LocalStorageProtocol: AnyObject {

    func save<T: Codable>(_ value: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func removeValue(forKey key: String)

    var trips: [Trip] { get set }
    var countries: [Country] { get set }
    var settings: UserSettings { get set }
    var wishlistCountries: [WishlistCountry] { get set }
}
