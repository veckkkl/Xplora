//
//  CatalogPlace.swift
//  Xplora
//

import Foundation

// MARK: - CatalogPlaceStatus

/// Product status of a place in the Xplora travel catalog.
/// Drives badges in the UI and which entries contribute to the "195" progress.
enum CatalogPlaceStatus: String, Equatable, Codable, Hashable {
    /// 193 UN member states + Vatican + Palestine. Counts toward the 195 progress.
    case un
    /// Disputed / partially recognised territories (Taiwan, Kosovo, ...). Does NOT count toward 195.
    case disputed
    /// Dependent territories, overseas regions, islands. Does NOT count toward 195.
    case territory
}

// MARK: - Continent

enum Continent: String, CaseIterable, Hashable {
    case africa, asia, europe, northAmerica, southAmerica, oceania, antarctica, other

    var localizedName: String {
        Bundle.main.localizedString(forKey: "continent.\(rawValue)", value: rawValue.capitalized, table: "Localizable")
    }
}

// MARK: - CatalogPlace

/// A place in the Xplora travel catalog: a UN country, disputed region, or territory.
/// The canonical identifier is an ISO 3166-1 alpha-2 code; display data
/// (name / flag / continent) is computed from `Foundation.Locale` so the type
/// stays minimal.
struct CatalogPlace: Equatable, Hashable, Codable {
    let code: String
    let status: CatalogPlaceStatus

    /// Flag emoji derived from the ISO code. May render as a placeholder for codes
    /// not recognised by the host system's font.
    var flag: String {
        String(code.unicodeScalars.compactMap { Unicode.Scalar(127397 + $0.value) }.map { Character($0) })
    }

    /// English name, kept for backward-compat (WishlistCountry stores this).
    var name: String {
        Locale(identifier: "en_US").localizedString(forRegionCode: code) ?? code
    }

    /// Name in the app's current locale.
    var localizedName: String {
        Locale.current.localizedString(forRegionCode: code) ?? name
    }

    /// Continent derived from the M49 region tree. Walks up `containingRegion`
    /// until a known M49 continent / subcontinent identifier is found. Returns
    /// `.other` when the host system can't classify the code.
    ///
    /// `Locale.Region.subcontinent` would be cleaner but is iOS 26+; the
    /// chain walk works on iOS 16+ and naturally handles the Americas split
    /// because a US's chain passes through `021` (Northern America) and a
    /// BR's chain passes through `005` (South America) before reaching the
    /// generic `019` Americas.
    var continent: Continent {
        var region: Locale.Region? = Locale.Region(code)
        for _ in 0..<8 { // M49 tree is shallow; guards against bad data
            guard let current = region else { break }
            if let mapped = Self.m49ToContinent(current.identifier) {
                return mapped
            }
            region = current.containingRegion
        }
        return .other
    }

    /// Maps M49 region identifiers to product continents.
    /// `003 North America`, `021 Northern America` and `029 Caribbean` all
    /// roll up into `.northAmerica` to match the existing UI grouping.
    private static func m49ToContinent(_ identifier: String) -> Continent? {
        switch identifier {
        case "002":                return .africa
        case "003", "021", "029":  return .northAmerica
        case "005":                return .southAmerica
        case "009":                return .oceania
        case "010":                return .antarctica
        case "142":                return .asia
        case "150":                return .europe
        default:                   return nil
        }
    }
}
