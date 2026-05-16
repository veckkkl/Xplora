//
//  CatalogCountry.swift
//  Xplora
//

import Foundation

// MARK: - Continent

enum Continent: String, CaseIterable, Hashable {
    case africa, asia, europe, northAmerica, southAmerica, oceania, antarctica

    var localizedName: String {
        Bundle.main.localizedString(forKey: "continent.\(rawValue)", value: rawValue.capitalized, table: "Localizable")
    }
}

// MARK: - CatalogCountry

/// Country reference identified by ISO 3166-1 alpha-2 code.
/// Continent and display names are derived from `Foundation.Locale`,
/// so the type itself only carries the canonical identifier.
struct CatalogCountry: Equatable, Hashable, Codable {
    let code: String

    /// Flag emoji derived from the ISO code.
    var flag: String {
        String(code.unicodeScalars.compactMap { Unicode.Scalar(127397 + $0.value) }.map { Character($0) })
    }

    /// English name, used when saving WishlistCountry for backward compat.
    var name: String {
        Locale(identifier: "en_US").localizedString(forRegionCode: code) ?? code
    }

    /// Name in the app's current locale.
    var localizedName: String {
        Locale.current.localizedString(forRegionCode: code) ?? name
    }

    /// Continent derived from the M49 region tree.
    /// Uses `subContinent` to split Americas into North/South, otherwise falls back to `continent`.
    var continent: Continent? {
        let region = Locale.Region(code)
        let identifier = region.subContinent?.identifier ?? region.continent?.identifier
        return identifier.flatMap(Self.m49ToContinent)
    }

    private static func m49ToContinent(_ identifier: String) -> Continent? {
        switch identifier {
        case "002": return .africa
        case "003": return .northAmerica
        case "005": return .southAmerica
        case "009": return .oceania
        case "010": return .antarctica
        case "142": return .asia
        case "150": return .europe
        default: return nil
        }
    }
}
