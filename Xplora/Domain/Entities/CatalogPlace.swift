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

    /// Continent derived from the M49 region tree. Uses `subContinent` to split
    /// Americas into North/South, falls back to `continent`, and `.other` when
    /// the host system can't classify the code.
    var continent: Continent {
        let region = Locale.Region(code)
        let identifier = region.subContinent?.identifier ?? region.continent?.identifier
        return identifier.flatMap(Self.m49ToContinent) ?? .other
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
