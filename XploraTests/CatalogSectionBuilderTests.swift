//
//  CatalogSectionBuilderTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct CatalogSectionBuilderTests {

    // Deterministic locale-independent comparator to keep ordering tests stable.
    private static let compare: (String, String) -> ComparisonResult = { $0.compare($1) }

    // MARK: - Search / sections share the catalog source

    @Test func searchOnlyReturnsPlacesAlsoPresentInSections() {
        let places = CatalogPlacePolicy.all
        let sections = CatalogSectionBuilder.continentSections(from: places, compare: Self.compare)
        let sectionCodes = codes(in: sections)

        let queries = ["fr", "uni", "is", "ger", "swed", "viet", "kor"]
        for query in queries {
            guard let section = CatalogSectionBuilder.searchResultsSection(
                from: places, query: query, compare: Self.compare
            ) else { continue }
            let searchCodes = codes(in: [section])
            for code in searchCodes {
                #expect(
                    sectionCodes.contains(code),
                    "Code \(code) appears in search for \"\(query)\" but is missing from continent sections"
                )
            }
        }
    }

    @Test func sectionsAndSearchUseTheSameCatalogReference() {
        // If both helpers consume the same `[CatalogPlace]` array, neither can
        // introduce a place that's absent from the other side.
        let places: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),
            CatalogPlace(code: "DE", status: .un)
        ]
        let sections = CatalogSectionBuilder.continentSections(from: places, compare: Self.compare)
        let search = CatalogSectionBuilder.searchResultsSection(
            from: places, query: "f", compare: Self.compare
        )

        let sectionCodes = codes(in: sections)
        let searchCodes = search.map { codes(in: [$0]) } ?? []

        for code in searchCodes {
            #expect(sectionCodes.contains(code))
        }
    }

    // MARK: - Other fallback only for supported places

    @Test func otherSectionExistsOnlyWhenNeeded() {
        // No unsupported codes, so Other should only appear if a supported
        // place lacks continent classification.
        let onlyClassifiable: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),
            CatalogPlace(code: "DE", status: .un)
        ]
        let sections = CatalogSectionBuilder.continentSections(from: onlyClassifiable, compare: Self.compare)
        #expect(!sections.contains(where: { $0.continent == .other }))
    }

    @Test func otherSectionContainsOnlySupportedPlacesPassedIn() {
        // Simulate a supported place whose continent classification falls back
        // to .other (would happen if Locale.Region couldn't classify it).
        // We achieve this by giving an unusual code that Locale can't map.
        // Note: "ZZ" is not a real ISO code so continent falls back to .other.
        let mixed: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),  // classifiable
            CatalogPlace(code: "ZZ", status: .territory) // not classifiable -> Other
        ]
        let sections = CatalogSectionBuilder.continentSections(from: mixed, compare: Self.compare)
        let otherSection = sections.first { $0.continent == .other }

        #expect(otherSection != nil)
        if let otherSection {
            let codesInOther = codes(in: [otherSection])
            // Only the place we explicitly passed is in Other; nothing else.
            #expect(codesInOther == ["ZZ"])
        }
    }

    // MARK: - Helpers

    private func codes(in sections: [CountrySection]) -> [String] {
        sections.flatMap { section in
            section.rows.compactMap { row -> String? in
                if case .country(let place) = row { return place.code }
                return nil
            }
        }
    }
}
