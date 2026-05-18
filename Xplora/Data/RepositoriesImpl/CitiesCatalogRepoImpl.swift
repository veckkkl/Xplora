//
//  CitiesCatalogRepoImpl.swift
//  Xplora
//

import Foundation

/// Cities catalog backed by the bundled data source and gated by the place
/// policy. Cities of unsupported places are dropped at the repo boundary so
/// no caller needs to repeat the check.
final class CitiesCatalogRepoImpl: CitiesCatalogRepo {
    private let supportedPlaceCodes: Set<String>
    private let bundledCities: [String: [CatalogCity]]

    init(
        supportedPlaceCodes: Set<String> = CatalogPlacePolicy.supportedCodes,
        bundledCities: [String: [CatalogCity]] = BundledCitiesDataSource.citiesByPlaceCode
    ) {
        self.supportedPlaceCodes = supportedPlaceCodes
        self.bundledCities = bundledCities
    }

    func cities(forPlaceCode code: String) async throws -> [CatalogCity] {
        let upper = code.uppercased()
        guard supportedPlaceCodes.contains(upper) else { return [] }
        guard let cities = bundledCities[upper] else { return [] }
        // Defensive: if a city slipped through with a mismatching placeCode,
        // skip it rather than violating the supported-place invariant.
        return cities.filter { $0.placeCode == upper }
    }

    func search(query: String) async throws -> [CatalogCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalized = trimmed
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        var seen: Set<String> = []
        var matches: [CatalogCity] = []

        for (code, cities) in bundledCities {
            guard supportedPlaceCodes.contains(code) else { continue }
            for city in cities {
                guard !seen.contains(city.id) else { continue }
                let displayMatch = city.displayName
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .contains(normalized)
                let fallbackMatch = city.fallbackName
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .contains(normalized)
                if displayMatch || fallbackMatch {
                    matches.append(city)
                    seen.insert(city.id)
                }
            }
        }

        return matches.sorted {
            $0.displayName.localizedCompare($1.displayName) == .orderedAscending
        }
    }
}
