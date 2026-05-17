//
//  CitiesCatalogRepoTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct CitiesCatalogRepoTests {

    // MARK: - curatedCities(forPlaceCode:)

    @Test func returnsCuratedForSupportedPlace() async throws {
        let repo = CitiesCatalogRepoImpl()
        let cities = try await repo.curatedCities(forPlaceCode: "FR")
        let fallbacks = cities.map(\.fallbackName)

        #expect(!cities.isEmpty)
        #expect(fallbacks.contains("Paris"))
        #expect(cities.allSatisfy { $0.placeCode == "FR" })
    }

    @Test func returnsEmptyCuratedForSupportedTerritory() async throws {
        let repo = CitiesCatalogRepoImpl()
        let cities = try await repo.curatedCities(forPlaceCode: "GL")
        #expect(cities.isEmpty)
    }

    @Test func returnsEmptyCuratedForUnsupportedPlaceCode() async throws {
        let repo = CitiesCatalogRepoImpl()
        let cities = try await repo.curatedCities(forPlaceCode: "ZZ")
        #expect(cities.isEmpty)
    }

    @Test func dropsCuratedCitiesWhosePlaceIsNotSupported() async throws {
        let synthetic: [String: [CatalogCity]] = [
            "FR": [CatalogCity(id: "FR-paris", fallbackName: "Paris", placeCode: "FR")],
            "ZZ": [CatalogCity(id: "ZZ-x", fallbackName: "X", placeCode: "ZZ")]
        ]
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: synthetic
        )
        #expect(try await repo.curatedCities(forPlaceCode: "FR").map(\.id) == ["FR-paris"])
        #expect(try await repo.curatedCities(forPlaceCode: "ZZ").isEmpty)
    }

    @Test func curatedLookupIsCaseInsensitive() async throws {
        let repo = CitiesCatalogRepoImpl()
        let lower = try await repo.curatedCities(forPlaceCode: "fr")
        let upper = try await repo.curatedCities(forPlaceCode: "FR")
        #expect(lower.map(\.id) == upper.map(\.id))
    }

    // MARK: - capital(forPlaceCode:)

    @Test func capitalReturnsAPIResult() async throws {
        let api = StubCountriesAPIClient(capital: ["France": "Paris"])
        let repo = Self.makeRepoBackedBy(api: api)

        let capital = try await repo.capital(forPlaceCode: "FR")
        #expect(capital?.fallbackName == "Paris")
        #expect(capital?.placeCode == "FR")
    }

    @Test func capitalReturnsNilWhenAPIErrors() async throws {
        let api = StubCountriesAPIClient(capitalError: TestError.boom)
        let repo = Self.makeRepoBackedBy(api: api)

        #expect(try await repo.capital(forPlaceCode: "FR") == nil)
    }

    @Test func capitalReturnsNilWhenAPIReturnsEmpty() async throws {
        let api = StubCountriesAPIClient(capital: ["France": nil])
        let repo = Self.makeRepoBackedBy(api: api)

        #expect(try await repo.capital(forPlaceCode: "FR") == nil)
    }

    @Test func capitalIsCachedAcrossCalls() async throws {
        let api = StubCountriesAPIClient(capital: ["France": "Paris"])
        let repo = Self.makeRepoBackedBy(api: api)

        _ = try await repo.capital(forPlaceCode: "FR")
        _ = try await repo.capital(forPlaceCode: "FR")
        #expect(api.capitalCallCount == 1)
    }

    @Test func capitalReturnsNilForUnsupportedPlace() async throws {
        let api = StubCountriesAPIClient(capital: ["Atlantis": "Pearl"])
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "Atlantis" }
        )
        #expect(try await repo.capital(forPlaceCode: "ZZ") == nil)
    }

    // MARK: - allCities(forPlaceCode:)

    @Test func allCitiesReturnsAPIResult() async throws {
        let api = StubCountriesAPIClient(cities: ["France": ["Paris", "Lyon", "Marseille"]])
        let repo = Self.makeRepoBackedBy(api: api)

        let cities = try await repo.allCities(forPlaceCode: "FR")
        #expect(cities.map(\.fallbackName) == ["Paris", "Lyon", "Marseille"])
        #expect(cities.allSatisfy { $0.placeCode == "FR" })
    }

    @Test func allCitiesReturnsEmptyOnAPIError() async throws {
        let api = StubCountriesAPIClient(citiesError: TestError.boom)
        let repo = Self.makeRepoBackedBy(api: api)

        #expect(try await repo.allCities(forPlaceCode: "FR").isEmpty)
    }

    @Test func allCitiesIsCachedAcrossCalls() async throws {
        let api = StubCountriesAPIClient(cities: ["France": ["Paris"]])
        let repo = Self.makeRepoBackedBy(api: api)

        _ = try await repo.allCities(forPlaceCode: "FR")
        _ = try await repo.allCities(forPlaceCode: "FR")
        #expect(api.citiesCallCount == 1)
    }

    // MARK: - search

    @Test func searchMatchesByFallbackName() async throws {
        let repo = CitiesCatalogRepoImpl()
        let results = try await repo.search(query: "paris")
        #expect(results.contains { $0.id == "FR-paris" })
    }

    @Test func searchIsDiacriticInsensitive() async throws {
        let repo = CitiesCatalogRepoImpl()
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
        let ids = results.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.contains("AR-patagonia"))
        #expect(ids.contains("CL-patagonia"))
    }

    @Test func searchSortsByDisplayName() async throws {
        let repo = CitiesCatalogRepoImpl()
        let results = try await repo.search(query: "san ")
        let displayNames = results.map(\.displayName)
        let sorted = displayNames.sorted { $0.localizedCompare($1) == .orderedAscending }
        #expect(displayNames == sorted)
    }

    @Test func emptyQueryReturnsEmpty() async throws {
        let repo = CitiesCatalogRepoImpl()
        #expect(try await repo.search(query: "").isEmpty)
        #expect(try await repo.search(query: "   ").isEmpty)
    }

    // MARK: - Helpers

    /// Repo wired with a single supported place "FR" mapped to "France" so
    /// stubs can key responses by country name.
    private static func makeRepoBackedBy(api: CountriesAPIClient) -> CitiesCatalogRepoImpl {
        CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "France" }
        )
    }
}
