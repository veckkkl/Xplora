// CountryCatalog.swift
// Xplora

import Foundation

// MARK: - Continent

enum Continent: String, CaseIterable, Hashable {
    case africa, asia, europe, northAmerica, southAmerica, oceania, antarctica

    var localizedName: String {
        Bundle.main.localizedString(forKey: "continent.\(rawValue)", value: rawValue.capitalized, table: "Localizable")
    }
}

// MARK: - CatalogCountry

struct CatalogCountry: Equatable, Hashable {
    let code: String
    let continent: Continent

    /// Flag emoji derived from the ISO 3166-1 alpha-2 code.
    var flag: String {
        String(code.unicodeScalars.compactMap { Unicode.Scalar(127397 + $0.value) }.map { Character($0) })
    }

    /// English name (used when saving WishlistCountry for backward compat).
    var name: String {
        Locale(identifier: "en_US").localizedString(forRegionCode: code) ?? code
    }

    /// Name in the app's current locale.
    var localizedName: String {
        Locale.current.localizedString(forRegionCode: code) ?? name
    }
}

// MARK: - CountryCatalog

enum CountryCatalog {
    private static func c(_ code: String, _ continent: Continent) -> CatalogCountry {
        CatalogCountry(code: code, continent: continent)
    }

    static let all: [CatalogCountry] = [
        // MARK: Africa (54)
        c("DZ", .africa), c("AO", .africa), c("BJ", .africa), c("BW", .africa),
        c("BF", .africa), c("BI", .africa), c("CV", .africa), c("CM", .africa),
        c("CF", .africa), c("TD", .africa), c("KM", .africa), c("CG", .africa),
        c("CD", .africa), c("DJ", .africa), c("EG", .africa), c("GQ", .africa),
        c("ER", .africa), c("SZ", .africa), c("ET", .africa), c("GA", .africa),
        c("GM", .africa), c("GH", .africa), c("GN", .africa), c("GW", .africa),
        c("CI", .africa), c("KE", .africa), c("LS", .africa), c("LR", .africa),
        c("LY", .africa), c("MG", .africa), c("MW", .africa), c("ML", .africa),
        c("MR", .africa), c("MU", .africa), c("MA", .africa), c("MZ", .africa),
        c("NA", .africa), c("NE", .africa), c("NG", .africa), c("RW", .africa),
        c("ST", .africa), c("SN", .africa), c("SC", .africa), c("SL", .africa),
        c("SO", .africa), c("ZA", .africa), c("SS", .africa), c("SD", .africa),
        c("TZ", .africa), c("TG", .africa), c("TN", .africa), c("UG", .africa),
        c("ZM", .africa), c("ZW", .africa),

        // MARK: North America (23)
        c("AG", .northAmerica), c("BS", .northAmerica), c("BB", .northAmerica),
        c("BZ", .northAmerica), c("CA", .northAmerica), c("CR", .northAmerica),
        c("CU", .northAmerica), c("DM", .northAmerica), c("DO", .northAmerica),
        c("SV", .northAmerica), c("GD", .northAmerica), c("GT", .northAmerica),
        c("HT", .northAmerica), c("HN", .northAmerica), c("JM", .northAmerica),
        c("MX", .northAmerica), c("NI", .northAmerica), c("PA", .northAmerica),
        c("KN", .northAmerica), c("LC", .northAmerica), c("VC", .northAmerica),
        c("TT", .northAmerica), c("US", .northAmerica),

        // MARK: South America (12)
        c("AR", .southAmerica), c("BO", .southAmerica), c("BR", .southAmerica),
        c("CL", .southAmerica), c("CO", .southAmerica), c("EC", .southAmerica),
        c("GY", .southAmerica), c("PY", .southAmerica), c("PE", .southAmerica),
        c("SR", .southAmerica), c("UY", .southAmerica), c("VE", .southAmerica),

        // MARK: Asia (48)
        c("AF", .asia), c("AM", .asia), c("AZ", .asia), c("BH", .asia),
        c("BD", .asia), c("BT", .asia), c("BN", .asia), c("KH", .asia),
        c("CN", .asia), c("CY", .asia), c("GE", .asia), c("IN", .asia),
        c("ID", .asia), c("IR", .asia), c("IQ", .asia), c("IL", .asia),
        c("JP", .asia), c("JO", .asia), c("KZ", .asia), c("KW", .asia),
        c("KG", .asia), c("LA", .asia), c("LB", .asia), c("MY", .asia),
        c("MV", .asia), c("MN", .asia), c("MM", .asia), c("NP", .asia),
        c("KP", .asia), c("OM", .asia), c("PK", .asia), c("PS", .asia),
        c("PH", .asia), c("QA", .asia), c("SA", .asia), c("SG", .asia),
        c("KR", .asia), c("LK", .asia), c("SY", .asia), c("TW", .asia),
        c("TJ", .asia), c("TH", .asia), c("TL", .asia), c("TM", .asia),
        c("AE", .asia), c("UZ", .asia), c("VN", .asia), c("YE", .asia),

        // MARK: Europe (44)
        c("AL", .europe), c("AD", .europe), c("AT", .europe), c("BY", .europe),
        c("BE", .europe), c("BA", .europe), c("BG", .europe), c("HR", .europe),
        c("CZ", .europe), c("DK", .europe), c("EE", .europe), c("FI", .europe),
        c("FR", .europe), c("DE", .europe), c("GR", .europe), c("HU", .europe),
        c("IS", .europe), c("IE", .europe), c("IT", .europe), c("LV", .europe),
        c("LI", .europe), c("LT", .europe), c("LU", .europe), c("MT", .europe),
        c("MD", .europe), c("MC", .europe), c("ME", .europe), c("NL", .europe),
        c("MK", .europe), c("NO", .europe), c("PL", .europe), c("PT", .europe),
        c("RO", .europe), c("RU", .europe), c("SM", .europe), c("RS", .europe),
        c("SK", .europe), c("SI", .europe), c("ES", .europe), c("SE", .europe),
        c("CH", .europe), c("TR", .europe), c("UA", .europe), c("GB", .europe),

        // MARK: Oceania (14)
        c("AU", .oceania), c("FJ", .oceania), c("KI", .oceania), c("MH", .oceania),
        c("FM", .oceania), c("NR", .oceania), c("NZ", .oceania), c("PW", .oceania),
        c("PG", .oceania), c("WS", .oceania), c("SB", .oceania), c("TO", .oceania),
        c("TV", .oceania), c("VU", .oceania),

        // MARK: Antarctica (2)
        c("AQ", .antarctica), c("TF", .antarctica),
    ]

    /// Countries sorted by their localized name within each continent.
    static var sorted: [CatalogCountry] {
        all.sorted { $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending }
    }
}
