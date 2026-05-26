// AddCountryRow.swift
// Xplora

import Foundation

enum AddCountryRow: Hashable {
    case country(CatalogPlace)
    case cityEntry(countryCode: String)
}

struct CountrySection: Equatable {
    /// `nil`        → flat search-results section (no header).
    /// `.other`     → fallback bucket for supported places whose continent
    ///                couldn't be classified (header is "Other").
    /// any other    → standard continent header.
    let continent: Continent?
    let rows: [AddCountryRow]
}
