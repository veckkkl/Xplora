//
//  CatalogPlacePolicy.swift
//  Xplora
//

import Foundation

/// Source of truth for the Xplora travel catalog. The allowlist is a product
/// decision: only places listed here are visible in the app, regardless of what
/// external APIs return. Adding/removing/changing status of an entry is a
/// deliberate product change.
///
/// Composition:
///   - 195 UN-level places: 193 UN member states + Holy See (VA) + Palestine (PS)
///   - Disputed / partially recognised: Taiwan, Kosovo
///   - Dependent territories / overseas regions / islands
///
/// Only UN-level places contribute to the "195" progress in statistics; the rest
/// are visible and selectable but tracked separately.
enum CatalogPlacePolicy {

    // MARK: - Public API

    /// Full catalog ordered as defined in this file (callers usually re-sort).
    static let all: [CatalogPlace] =
        unMemberStates + specialUNPlaces + disputedPlaces + territoryPlaces

    /// Codes contributing to the 195 main progress.
    static var unProgressCodes: Set<String> {
        Set(all.filter { $0.status == .un }.map(\.code))
    }

    /// All codes accepted by the catalog. Used to filter external sources.
    static var supportedCodes: Set<String> {
        Set(all.map(\.code))
    }

    static func place(forCode code: String) -> CatalogPlace? {
        all.first { $0.code == code }
    }

    /// Filters a list of external codes to those present in the catalog,
    /// preserving the policy-declared status (NOT the order from the input).
    static func filter(codes: [String]) -> [CatalogPlace] {
        let inputSet = Set(codes.map { $0.uppercased() })
        return all.filter { inputSet.contains($0.code) }
    }

    // MARK: - Helpers

    private static func un(_ code: String) -> CatalogPlace {
        CatalogPlace(code: code, status: .un)
    }
    private static func disputed(_ code: String) -> CatalogPlace {
        CatalogPlace(code: code, status: .disputed)
    }
    private static func territory(_ code: String) -> CatalogPlace {
        CatalogPlace(code: code, status: .territory)
    }

    // MARK: - Allowlist

    /// 193 UN member states. Sorted by ISO code within each continent block for auditability.
    private static let unMemberStates: [CatalogPlace] = [
        // Africa (54)
        un("DZ"), un("AO"), un("BJ"), un("BW"), un("BF"), un("BI"), un("CV"), un("CM"),
        un("CF"), un("TD"), un("KM"), un("CG"), un("CD"), un("DJ"), un("EG"), un("GQ"),
        un("ER"), un("SZ"), un("ET"), un("GA"), un("GM"), un("GH"), un("GN"), un("GW"),
        un("CI"), un("KE"), un("LS"), un("LR"), un("LY"), un("MG"), un("MW"), un("ML"),
        un("MR"), un("MU"), un("MA"), un("MZ"), un("NA"), un("NE"), un("NG"), un("RW"),
        un("ST"), un("SN"), un("SC"), un("SL"), un("SO"), un("ZA"), un("SS"), un("SD"),
        un("TZ"), un("TG"), un("TN"), un("UG"), un("ZM"), un("ZW"),

        // Americas - North & Central (23)
        un("AG"), un("BS"), un("BB"), un("BZ"), un("CA"), un("CR"), un("CU"), un("DM"),
        un("DO"), un("SV"), un("GD"), un("GT"), un("HT"), un("HN"), un("JM"), un("MX"),
        un("NI"), un("PA"), un("KN"), un("LC"), un("VC"), un("TT"), un("US"),

        // Americas - South (12)
        un("AR"), un("BO"), un("BR"), un("CL"), un("CO"), un("EC"), un("GY"), un("PY"),
        un("PE"), un("SR"), un("UY"), un("VE"),

        // Asia (47 — excludes Taiwan, which is listed as disputed below)
        un("AF"), un("AM"), un("AZ"), un("BH"), un("BD"), un("BT"), un("BN"), un("KH"),
        un("CN"), un("CY"), un("GE"), un("IN"), un("ID"), un("IR"), un("IQ"), un("IL"),
        un("JP"), un("JO"), un("KZ"), un("KW"), un("KG"), un("LA"), un("LB"), un("MY"),
        un("MV"), un("MN"), un("MM"), un("NP"), un("KP"), un("OM"), un("PK"), un("PH"),
        un("QA"), un("SA"), un("SG"), un("KR"), un("LK"), un("SY"), un("TJ"), un("TH"),
        un("TL"), un("TM"), un("AE"), un("UZ"), un("VN"), un("YE"),

        // Europe (43)
        un("AL"), un("AD"), un("AT"), un("BY"), un("BE"), un("BA"), un("BG"), un("HR"),
        un("CZ"), un("DK"), un("EE"), un("FI"), un("FR"), un("DE"), un("GR"), un("HU"),
        un("IS"), un("IE"), un("IT"), un("LV"), un("LI"), un("LT"), un("LU"), un("MT"),
        un("MD"), un("MC"), un("ME"), un("NL"), un("MK"), un("NO"), un("PL"), un("PT"),
        un("RO"), un("RU"), un("SM"), un("RS"), un("SK"), un("SI"), un("ES"), un("SE"),
        un("CH"), un("TR"), un("UA"), un("GB"),

        // Oceania (14)
        un("AU"), un("FJ"), un("KI"), un("MH"), un("FM"), un("NR"), un("NZ"), un("PW"),
        un("PG"), un("WS"), un("SB"), un("TO"), un("TV"), un("VU"),
    ]

    /// Holy See and Palestine: not UN members but tracked as part of the 195
    /// for product reasons (UN observer states).
    private static let specialUNPlaces: [CatalogPlace] = [
        un("VA"), // Holy See / Vatican City
        un("PS"), // State of Palestine
    ]

    private static let disputedPlaces: [CatalogPlace] = [
        disputed("TW"), // Taiwan, Republic of China
        disputed("XK"), // Kosovo
    ]

    /// Curated territories — dependent regions, overseas regions, popular islands.
    /// Not exhaustive; entries are added as the product grows.
    private static let territoryPlaces: [CatalogPlace] = [
        // Crown dependencies & UK overseas (selected)
        territory("IM"), // Isle of Man
        territory("JE"), // Jersey
        territory("GG"), // Guernsey
        territory("GI"), // Gibraltar
        territory("BM"), // Bermuda
        territory("KY"), // Cayman Islands

        // US overseas
        territory("PR"), // Puerto Rico
        territory("VI"), // US Virgin Islands
        territory("GU"), // Guam
        territory("AS"), // American Samoa
        territory("MP"), // Northern Mariana Islands

        // Greater China SARs
        territory("HK"), // Hong Kong
        territory("MO"), // Macao

        // Nordic / Atlantic
        territory("GL"), // Greenland
        territory("FO"), // Faroe Islands

        // Caribbean (Dutch + French)
        territory("AW"), // Aruba

        // Pacific - French
        territory("PF"), // French Polynesia

        // Antarctica region (preserved from prior catalog; surfaced for tracking purposes)
        territory("AQ"), // Antarctica
        territory("TF"), // French Southern Territories
    ]
}
