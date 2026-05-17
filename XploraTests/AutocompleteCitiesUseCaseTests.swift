//
//  AutocompleteCitiesUseCaseTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct AutocompleteCitiesUseCaseTests {

    // MARK: - Filtering

    @Test func filtersCaseInsensitive() async throws {
        let useCase = Self.makeUseCase(
            cities: ["France": ["Paris", "Lyon", "Marseille"]]
        )
        let lower = try await useCase.execute(query: "par", placeCode: "FR")
        let upper = try await useCase.execute(query: "PAR", placeCode: "FR")
        let mixed = try await useCase.execute(query: "Par", placeCode: "FR")

        #expect(lower.map(\.fallbackName) == ["Paris"])
        #expect(upper.map(\.fallbackName) == ["Paris"])
        #expect(mixed.map(\.fallbackName) == ["Paris"])
    }

    @Test func prefixMatchesAreReturnedBeforeContains() async throws {
        let useCase = Self.makeUseCase(
            cities: ["France": ["Champaris", "Paris", "Parislike"]]
        )
        let result = try await useCase.execute(query: "par", placeCode: "FR")
        let names = result.map(\.fallbackName)
        // "Paris" and "Parislike" start with "par" → first.
        // "Champaris" only contains → after.
        #expect(names.firstIndex(of: "Paris")! < names.firstIndex(of: "Champaris")!)
        #expect(names.firstIndex(of: "Parislike")! < names.firstIndex(of: "Champaris")!)
    }

    @Test func returnsAtMostFiveResults() async throws {
        let cities = (1...20).map { "City\($0)" }
        let useCase = Self.makeUseCase(cities: ["France": cities])

        let result = try await useCase.execute(query: "city", placeCode: "FR")
        #expect(result.count == 5)
    }

    @Test func returnsEmptyBelowMinQueryLength() async throws {
        let useCase = Self.makeUseCase(cities: ["France": ["Paris"]])
        let result = try await useCase.execute(query: "p", placeCode: "FR")
        #expect(result.isEmpty)
    }

    @Test func returnsEmptyForUnsupportedPlace() async throws {
        // Place ZZ is not supported by policy, so allCities is gated to empty.
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: [:],
            api: StubCountriesAPIClient(cities: ["France": ["Paris"]]),
            countryNameProvider: { _ in "France" }
        )
        let useCase = AutocompleteCitiesUseCaseImpl(repo: repo)
        let result = try await useCase.execute(query: "par", placeCode: "ZZ")
        #expect(result.isEmpty)
    }

    @Test func diacriticInsensitiveMatching() async throws {
        let useCase = Self.makeUseCase(
            cities: ["France": ["São Paulo", "Paris"]]
        )
        let result = try await useCase.execute(query: "sao", placeCode: "FR")
        #expect(result.contains { $0.fallbackName == "São Paulo" })
    }

    @Test func resultsAreDeduplicatedById() async throws {
        // Synthetic case: even if the API would somehow return two identical
        // city names, the dedup via id (which depends on slug + index) keeps
        // the list clean.
        let useCase = Self.makeUseCase(
            cities: ["France": ["Paris", "Paris"]]
        )
        let result = try await useCase.execute(query: "par", placeCode: "FR")
        let ids = result.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func emptyWhenAPIReturnsNothing() async throws {
        let useCase = Self.makeUseCase(cities: ["France": []])
        let result = try await useCase.execute(query: "par", placeCode: "FR")
        #expect(result.isEmpty)
    }

    // MARK: - Prefetch

    @Test func prefetchPopulatesCacheSoLaterCallsAreFree() async throws {
        let api = StubCountriesAPIClient(cities: ["France": ["Paris", "Lyon"]])
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "France" }
        )
        let useCase = AutocompleteCitiesUseCaseImpl(repo: repo)

        await useCase.prefetch(placeCode: "FR")
        _ = try await useCase.execute(query: "par", placeCode: "FR")

        #expect(api.citiesCallCount == 1)
    }

    @Test func prefetchSwallowsErrors() async throws {
        let api = StubCountriesAPIClient(citiesError: TestError.boom)
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "France" }
        )
        let useCase = AutocompleteCitiesUseCaseImpl(repo: repo)

        // Must not throw — repo absorbs the API error and caches an empty list.
        await useCase.prefetch(placeCode: "FR")
        let result = try await useCase.execute(query: "par", placeCode: "FR")
        #expect(result.isEmpty)
    }

    // MARK: - Helpers

    private static func makeUseCase(
        cities: [String: [String]],
        limit: Int = 5,
        minQueryLength: Int = 2
    ) -> AutocompleteCitiesUseCaseImpl {
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["FR"],
            bundledCities: [:],
            api: StubCountriesAPIClient(cities: cities),
            countryNameProvider: { _ in "France" }
        )
        return AutocompleteCitiesUseCaseImpl(
            repo: repo,
            limit: limit,
            minQueryLength: minQueryLength
        )
    }
}
