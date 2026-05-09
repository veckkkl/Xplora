// AddCountryRow.swift
// Xplora

import Foundation

enum AddCountryRow: Hashable {
    case country(CatalogCountry)
    case cityEntry(countryCode: String)
}

struct CountrySection {
    let continent: Continent?   // nil = flat results during search
    let rows: [AddCountryRow]
}
