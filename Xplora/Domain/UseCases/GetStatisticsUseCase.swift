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
    private let getTrips: GetTripsUseCase

    init(getCatalogPlaces: GetCatalogPlacesUseCase,
         getTrips: GetTripsUseCase) {
        self.getCatalogPlaces = getCatalogPlaces
        self.getTrips = getTrips
    }

    /// Visited countries come from Timeline trips — `Trip.placeCode` is the
    /// canonical source. A trip to Hong Kong (`HK`) or Taiwan (`TW`) is a real
    /// visit and remains in the timeline, but only places whose catalog status
    /// is `.un` contribute to the "195 UN" progress. We never collapse
    /// territories into their parent country.
    func execute() async throws -> StatisticsSummary {
        async let catalogTask = getCatalogPlaces.execute()
        async let tripsTask = getTrips.execute()

        let (allPlaces, trips) = try await (catalogTask, tripsTask)

        let visitedPlaceCodes: Set<String> = Set(
            trips.map { $0.placeCode.uppercased() }
        )

        let unPlaces = allPlaces.filter { $0.status == .un }
        let visitedUNCodes: Set<String> = Set(
            unPlaces
                .map { $0.code.uppercased() }
                .filter { visitedPlaceCodes.contains($0) }
        )

        let totalUNCount = unPlaces.count
        let visitedUNCount = visitedUNCodes.count
        let worldProgressPercent = totalUNCount > 0
            ? Int((Double(visitedUNCount) / Double(totalUNCount) * 100).rounded())
            : 0

        let continentItems: [StatisticsContinentItem] = Self.orderedContinents.map { continent in
            let continentPlaces = unPlaces.filter { $0.continent == continent }
            let continentVisited = continentPlaces
                .filter { visitedUNCodes.contains($0.code.uppercased()) }
                .count
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
