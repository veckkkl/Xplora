//
//  CitiesCatalogRepoTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct CitiesCatalogRepoTests {

    // MARK: - cities(forPlaceCode:)

    @Test func returnsCitiesForSupportedPlace() async throws {
        let repo = CitiesCatalogRepoImpl()
        let cities = try await repo.cities(forPlaceCode: "FR")
        let fallbacks = cities.map(\.fallbackName)

        #expect(!cities.isEmpty)
        #expect(fallbacks.contains("Paris"))
        #expect(cities.allSatisfy { $0.placeCode == "FR" })
    }

    @Test func returnsCitiesForSupportedTerritory() async throws {
        // Greenland is in policy as .territory and seeded with no curated
        // cities in the bundled source — should return empty, not error.
        let repo = CitiesCatalogRepoImpl()
        let cities = try await repo.cities(forPlaceCode: "GL")
        #expect(cities.isEmpty)
    }

    @Test func returnsEmptyForUnsupportedPlaceCode() async throws {
        let repo = CitiesCatalogRepoImpl()
        let cities = try await repo.cities(forPlaceCode: "ZZ")
        #expect(cities.isEmpty)
    }

    @Test func dropsCitiesWhosePlaceIsNotSupported() async throws {
        // Build a synthetic repo where the bundled source contains a place
        // that's NOT in the policy (`ZZ`). The repo must filter it out.
        let synthetic: [String: [CatalogCity]] = [
            "FR": [CatalogCity(id: "FR-paris", fallbackName: "Paris", placeCode: "FR")],
            "ZZ": [CatalogCity(id: "ZZ-x", fallbackName: "X", placeCode: "ZZ")]
        ]
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: synthetic
        )
        #expect(try await repo.cities(forPlaceCode: "FR").map(\.id) == ["FR-paris"])
        #expect(try await repo.cities(forPlaceCode: "ZZ").isEmpty)
    }

    @Test func placeCodeLookupIsCaseInsensitive() async throws {
        let repo = CitiesCatalogRepoImpl()
        let lower = try await repo.cities(forPlaceCode: "fr")
        let upper = try await repo.cities(forPlaceCode: "FR")
        #expect(lower.map(\.id) == upper.map(\.id))
    }

    // MARK: - search

    @Test func searchMatchesByFallbackName() async throws {
        let repo = CitiesCatalogRepoImpl()
        let results = try await repo.search(query: "paris")
        #expect(results.contains { $0.id == "FR-paris" })
    }

    @Test func searchIsDiacriticInsensitive() async throws {
        let repo = CitiesCatalogRepoImpl()
        // "São Paulo" -> match plain "sao"
        let results = try await repo.search(query: "sao")
        #expect(results.contains { $0.id == "BR-sao_paulo" })
    }

    @Test func searchSkipsCitiesOfUnsupportedPlaces() async throws {
        let synthetic: [String: [CatalogCity]] = [
            "ZZ": [CatalogCity(id: "ZZ-paris", fallbackName: "Paris", placeCode: "ZZ")]
        ]
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: synthetic
        )
        let results = try await repo.search(query: "paris")
        #expect(results.isEmpty)
    }

    @Test func searchReturnsUniqueIDs() async throws {
        let repo = CitiesCatalogRepoImpl()
        let results = try await repo.search(query: "patagonia")
        // "Patagonia" exists for both AR and CL — distinct ids, both expected.
        let ids = results.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.contains("AR-patagonia"))
        #expect(ids.contains("CL-patagonia"))
    }

    @Test func searchSortsByDisplayName() async throws {
        let repo = CitiesCatalogRepoImpl()
        let results = try await repo.search(query: "san ")
        // "San Pedro de Atacama" and "San Francisco" both match.
        let displayNames = results.map(\.displayName)
        let sorted = displayNames.sorted { $0.localizedCompare($1) == .orderedAscending }
        #expect(displayNames == sorted)
    }

    @Test func emptyQueryReturnsEmpty() async throws {
        let repo = CitiesCatalogRepoImpl()
        #expect(try await repo.search(query: "").isEmpty)
        #expect(try await repo.search(query: "   ").isEmpty)
    }
}
