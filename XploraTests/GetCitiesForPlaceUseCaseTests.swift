//
//  GetCitiesForPlaceUseCaseTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct GetCitiesForPlaceUseCaseTests {

    @Test func returnsCuratedCitiesForFrance() async throws {
        let useCase = GetCitiesForPlaceUseCaseImpl(repo: CitiesCatalogRepoImpl())
        let cities = try await useCase.execute(placeCode: "FR")
        #expect(cities.contains { $0.fallbackName == "Paris" })
        #expect(cities.allSatisfy { $0.placeCode == "FR" })
    }

    @Test func returnsEmptyForUnsupportedCode() async throws {
        let useCase = GetCitiesForPlaceUseCaseImpl(repo: CitiesCatalogRepoImpl())
        #expect(try await useCase.execute(placeCode: "ZZ").isEmpty)
    }

    @Test func disputedAndTerritoryCitiesShareSameFlowAsUNCities() async throws {
        // Taiwan is .disputed in policy; Hong Kong is .territory.
        // The catalog should accept both place codes uniformly: empty list
        // when no cities are curated, never an error.
        let useCase = GetCitiesForPlaceUseCaseImpl(repo: CitiesCatalogRepoImpl())
        let tw = try await useCase.execute(placeCode: "TW")
        let hk = try await useCase.execute(placeCode: "HK")
        #expect(tw.isEmpty)
        #expect(hk.isEmpty)
    }
}
