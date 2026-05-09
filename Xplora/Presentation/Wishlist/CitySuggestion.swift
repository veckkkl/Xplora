// CitySuggestion.swift
// Xplora

import Foundation

struct CitySuggestion: Hashable {
    let key: String         // e.g. "city.FR.normandy"
    let countryCode: String

    var displayName: String {
        let resolved = Bundle.main.localizedString(forKey: key, value: nil, table: "Localizable")
        return resolved != key ? resolved : key
    }
}
