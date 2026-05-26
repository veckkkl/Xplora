//
//  GetStatisticsUseCase.swift
//  Xplora
//

import Foundation

protocol GetStatisticsUseCase {
    func execute() async throws -> StatisticsSummary
}

final class GetStatisticsUseCaseImpl: GetStatisticsUseCase {

    private static let orderedContinents: [Continent] = [
        .africa, .asia, .europe, .northAmerica, .southAmerica, .oceania, .antarctica
    ]

    private let getCatalogPlaces: GetCatalogPlacesUseCase
    private let getVisitedCountries: GetVisitedCountriesUseCase

    init(getCatalogPlaces: GetCatalogPlacesUseCase,
         getVisitedCountries: GetVisitedCountriesUseCase) {
        self.getCatalogPlaces = getCatalogPlaces
        self.getVisitedCountries = getVisitedCountries
    }

    func execute() async throws -> StatisticsSummary {
        async let catalogTask = getCatalogPlaces.execute()
        async let visitedTask = getVisitedCountries.execute()

        let (allPlaces, visitedCountries) = try await (catalogTask, visitedTask)

        let unPlaces = allPlaces.filter { $0.status == .un }
        let visitedCodes = Set(visitedCountries.map { $0.code.uppercased() })

        let totalUNCount = unPlaces.count
        let visitedUNCount = unPlaces.filter { visitedCodes.contains($0.code.uppercased()) }.count
        let worldProgressPercent = totalUNCount > 0
            ? Int((Double(visitedUNCount) / Double(totalUNCount) * 100).rounded())
            : 0

        let continentItems: [StatisticsContinentItem] = Self.orderedContinents.map { continent in
            let continentPlaces = unPlaces.filter { $0.continent == continent }
            let continentVisited = continentPlaces.filter { visitedCodes.contains($0.code.uppercased()) }.count
            return StatisticsContinentItem(
                continent: continent,
                visitedCount: continentVisited,
                totalCount: continentPlaces.count
            )
        }

        let visitedContinentsCount = continentItems.filter { $0.visitedCount > 0 }.count

        return StatisticsSummary(
            totalUNCount: totalUNCount,
            visitedUNCount: visitedUNCount,
            worldProgressPercent: worldProgressPercent,
            visitedContinentsCount: visitedContinentsCount,
            totalContinentsCount: Self.orderedContinents.count,
            continentItems: continentItems
        )
    }
}
