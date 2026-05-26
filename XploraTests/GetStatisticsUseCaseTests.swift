//
//  GetStatisticsUseCaseTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct GetStatisticsUseCaseTests {

    // MARK: - Empty state

    @Test func emptyVisitedCountriesProducesZeroProgress() async throws {
        let sut = makeUseCase(visitedCodes: [])
        let result = try await sut.execute()
        #expect(result.visitedUNCount == 0)
        #expect(result.worldProgressPercent == 0)
        #expect(result.visitedContinentsCount == 0)
    }

    // MARK: - UN filtering

    @Test func onlyUNPlacesCountTowardTotals() async throws {
        let catalog: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),
            CatalogPlace(code: "TW", status: .disputed),
            CatalogPlace(code: "HK", status: .territory)
        ]
        let sut = makeUseCase(catalog: catalog, visitedCodes: ["FR", "TW", "HK"])
        let result = try await sut.execute()
        #expect(result.totalUNCount == 1)
        #expect(result.visitedUNCount == 1)
    }

    // MARK: - World progress percent

    @Test func worldProgressPercentIsRounded() async throws {
        // 1 visited out of 3 UN = 33%
        let catalog: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),
            CatalogPlace(code: "DE", status: .un),
            CatalogPlace(code: "ES", status: .un)
        ]
        let sut = makeUseCase(catalog: catalog, visitedCodes: ["FR"])
        let result = try await sut.execute()
        #expect(result.worldProgressPercent == 33)
    }

    @Test func worldProgressIs100WhenAllVisited() async throws {
        let catalog: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),
            CatalogPlace(code: "DE", status: .un)
        ]
        let sut = makeUseCase(catalog: catalog, visitedCodes: ["FR", "DE"])
        let result = try await sut.execute()
        #expect(result.worldProgressPercent == 100)
    }

    // MARK: - Continent counting

    @Test func visitedContinentsCountOnlyCountinentsWithAtLeastOneVisit() async throws {
        // FR and DE are both Europe; JP is Asia.
        let catalog: [CatalogPlace] = [
            CatalogPlace(code: "FR", status: .un),
            CatalogPlace(code: "DE", status: .un),
            CatalogPlace(code: "JP", status: .un)
        ]
        let sut = makeUseCase(catalog: catalog, visitedCodes: ["FR"])
        let result = try await sut.execute()
        #expect(result.visitedContinentsCount == 1)
    }

    @Test func totalContinentsCountIsAlwaysSeven() async throws {
        let sut = makeUseCase(visitedCodes: [])
        let result = try await sut.execute()
        #expect(result.totalContinentsCount == 7)
    }

    // MARK: - Continent items ordering

    @Test func continentItemsAreInCanonicalOrder() async throws {
        let sut = makeUseCase(visitedCodes: [])
        let result = try await sut.execute()
        let expected: [Continent] = [.africa, .asia, .europe, .northAmerica, .southAmerica, .oceania, .antarctica]
        #expect(result.continentItems.map(\.continent) == expected)
    }

    // MARK: - Code case-insensitivity

    @Test func visitedCodeMatchingIsCaseInsensitive() async throws {
        let catalog: [CatalogPlace] = [CatalogPlace(code: "FR", status: .un)]
        let sut = makeUseCase(catalog: catalog, visitedCodes: ["fr"])
        let result = try await sut.execute()
        #expect(result.visitedUNCount == 1)
    }

    // MARK: - Full catalog smoke test

    @Test func fullCatalogTotalMatchesExpectedUNCount() async throws {
        let sut = makeUseCase(visitedCodes: [])
        let result = try await sut.execute()
        // CatalogPlacePolicy defines 195 UN places (193 UN members + Vatican + Palestine).
        #expect(result.totalUNCount == 195)
    }

    // MARK: - Helpers

    private func makeUseCase(
        catalog: [CatalogPlace]? = nil,
        visitedCodes: [String]
    ) -> GetStatisticsUseCaseImpl {
        let places = catalog ?? CatalogPlacePolicy.all
        let visited = visitedCodes.map { code in
            Country(id: UUID(), code: code, name: code, regions: [])
        }
        return GetStatisticsUseCaseImpl(
            getCatalogPlaces: StubCatalogPlacesUseCase(places: places),
            getVisitedCountries: StubVisitedCountriesUseCase(countries: visited)
        )
    }
}

// MARK: - Stubs

private final class StubCatalogPlacesUseCase: GetCatalogPlacesUseCase {
    private let places: [CatalogPlace]
    init(places: [CatalogPlace]) { self.places = places }
    func execute() async throws -> [CatalogPlace] { places }
}

private final class StubVisitedCountriesUseCase: GetVisitedCountriesUseCase {
    private let countries: [Country]
    init(countries: [Country]) { self.countries = countries }
    func execute() async throws -> [Country] { countries }
}
