//
//  AutocompleteCitiesUseCase.swift
//  Xplora
//

import Foundation

protocol AutocompleteCitiesUseCase {
    /// Runs autocomplete against the full city list of `placeCode`.
    /// Returns at most `limit` matches; prefix matches take priority,
    /// substring matches fill the remaining slots. Case- and diacritic-
    /// insensitive. Empty when the query is shorter than `minQueryLength`,
    /// the API is unavailable, or there are no matches.
    func execute(query: String, placeCode: String) async throws -> [CatalogCity]

    /// Warms the underlying city cache for a place so the first keystroke
    /// already has data available. Errors are swallowed.
    func prefetch(placeCode: String) async
}

final class AutocompleteCitiesUseCaseImpl: AutocompleteCitiesUseCase {
    private let repo: CitiesCatalogRepo
    private let limit: Int
    private let minQueryLength: Int

    init(repo: CitiesCatalogRepo, limit: Int = 5, minQueryLength: Int = 2) {
        self.repo = repo
        self.limit = limit
        self.minQueryLength = minQueryLength
    }

    func execute(query: String, placeCode: String) async throws -> [CatalogCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minQueryLength else { return [] }

        let normalized = trimmed
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let all = try await repo.allCities(forPlaceCode: placeCode)

        var prefixed: [CatalogCity] = []
        var contained: [CatalogCity] = []
        for city in all {
            let folded = city.fallbackName
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            if folded.hasPrefix(normalized) {
                prefixed.append(city)
            } else if folded.contains(normalized) {
                contained.append(city)
            }
        }

        var result: [CatalogCity] = []
        var seen: Set<String> = []
        for city in prefixed + contained {
            if seen.contains(city.id) { continue }
            result.append(city)
            seen.insert(city.id)
            if result.count >= limit { break }
        }
        return result
    }

    func prefetch(placeCode: String) async {
        _ = try? await repo.allCities(forPlaceCode: placeCode)
    }
}
