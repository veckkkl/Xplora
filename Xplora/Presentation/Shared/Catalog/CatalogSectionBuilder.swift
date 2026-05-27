// CatalogSectionBuilder.swift
// Xplora

import Foundation

/// Pure section/search builder shared by `AddWishlistCountryViewController` and
/// unit tests. Keeping it outside the VC ensures the same code path produces
/// both the section view and the search results — there's no way for a place
/// to appear in one but not the other.
enum CatalogSectionBuilder {

    /// Builds continent-grouped sections from the given catalog. Places without
    /// a classifiable continent land in the trailing `.other` section. Each
    /// section is sorted by the supplied locale-aware comparator.
    /// `expandedCode` causes the matching country row to be followed by a
    /// `.cityEntry` row.
    static func continentSections(
        from places: [CatalogPlace],
        expandedCode: String? = nil,
        compare: (String, String) -> ComparisonResult = { $0.localizedCompare($1) }
    ) -> [CountrySection] {
        Continent.allCases.compactMap { continent in
            let rows = places
                .filter { $0.continent == continent }
                .sorted { compare($0.localizedName, $1.localizedName) == .orderedAscending }
                .flatMap { expandedRows(for: $0, expandedCode: expandedCode) }
            return rows.isEmpty ? nil : CountrySection(continent: continent, rows: rows)
        }
    }

    /// Builds the search results section. Empty query returns `nil`.
    static func searchResultsSection(
        from places: [CatalogPlace],
        query: String,
        expandedCode: String? = nil,
        compare: (String, String) -> ComparisonResult = { $0.localizedCompare($1) }
    ) -> CountrySection? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let rows = places
            .filter {
                $0.localizedName
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .hasPrefix(normalized)
            }
            .sorted { compare($0.localizedName, $1.localizedName) == .orderedAscending }
            .flatMap { expandedRows(for: $0, expandedCode: expandedCode) }

        return rows.isEmpty ? nil : CountrySection(continent: nil, rows: rows)
    }

    private static func expandedRows(for place: CatalogPlace, expandedCode: String?) -> [AddCountryRow] {
        var result: [AddCountryRow] = [.country(place)]
        if let expandedCode, place.code == expandedCode {
            result.append(.cityEntry(countryCode: place.code))
        }
        return result
    }
}
