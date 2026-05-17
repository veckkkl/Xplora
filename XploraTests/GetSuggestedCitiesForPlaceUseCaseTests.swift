//
//  GetSuggestedCitiesForPlaceUseCaseTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct GetSuggestedCitiesForPlaceUseCaseTests {

    // MARK: - Curated wins over capital

    @Test func curatedSuggestionsArePreferredOverCapital() async throws {
        // France has curated cities in the bundled source. Even though the
        // stub API knows a different capital, curated must be the result and
        // no API call should happen.
        let api = StubCountriesAPIClient(capital: ["France": "WrongCity"])
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: CatalogPlacePolicy.supportedCodes,
            api: api,
            countryNameProvider: { _ in "France" }
        )
        let useCase = GetSuggestedCitiesForPlaceUseCaseImpl(repo: repo)

        let result = try await useCase.execute(placeCode: "FR")
        let names = result.map(\.fallbackName)
        #expect(names.contains("Paris"))
        #expect(!names.contains("WrongCity"))
        #expect(api.capitalCallCount == 0)
    }

    // MARK: - Capital fallback

    @Test func capitalFallbackForCountryWithoutCuratedSuggestions() async throws {
        // Greenland is supported in policy but has no curated entries.
        // The use case asks the repo for the capital and wraps it.
        let api = StubCountriesAPIClient(capital: ["Greenland": "Nuuk"])
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["GL"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "Greenland" }
        )
        let useCase = GetSuggestedCitiesForPlaceUseCaseImpl(repo: repo)

        let result = try await useCase.execute(placeCode: "GL")
        #expect(result.count == 1)
        #expect(result.first?.fallbackName == "Nuuk")
        #expect(result.first?.placeCode == "GL")
    }

    @Test func capitalFallbackEmptyWhenAPIErrors() async throws {
        let api = StubCountriesAPIClient(capitalError: TestError.boom)
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["GL"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "Greenland" }
        )
        let useCase = GetSuggestedCitiesForPlaceUseCaseImpl(repo: repo)

        let result = try await useCase.execute(placeCode: "GL")
        #expect(result.isEmpty)
    }

    @Test func capitalFallbackEmptyWhenAPIReturnsNil() async throws {
        let api = StubCountriesAPIClient(capital: ["Greenland": nil])
        let repo = CitiesCatalogRepoImpl(
            supportedPlaceCodes: ["GL"],
            bundledCities: [:],
            api: api,
            countryNameProvider: { _ in "Greenland" }
        )
        let useCase = GetSuggestedCitiesForPlaceUseCaseImpl(repo: repo)

        let result = try await useCase.execute(placeCode: "GL")
        #expect(result.isEmpty)
    }

    @Test func returnsEmptyForUnsupportedCode() async throws {
        let useCase = GetSuggestedCitiesForPlaceUseCaseImpl(repo: CitiesCatalogRepoImpl())
        #expect(try await useCase.execute(placeCode: "ZZ").isEmpty)
    }

    @Test func disputedAndTerritoryShareSameFlowAsUNCountries() async throws {
        // TW (.disputed) and HK (.territory) have no curated entries and
        // (in tests, without an API) no capital either. Use case returns
        // empty for both without errors.
        let useCase = GetSuggestedCitiesForPlaceUseCaseImpl(repo: CitiesCatalogRepoImpl())
        let tw = try await useCase.execute(placeCode: "TW")
        let hk = try await useCase.execute(placeCode: "HK")
        #expect(tw.isEmpty)
        #expect(hk.isEmpty)
    }
}
