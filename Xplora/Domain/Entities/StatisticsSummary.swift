//
//  StatisticsSummary.swift
//  Xplora
//

import Foundation

struct StatisticsSummary: Equatable {
    let totalUNCount: Int
    let visitedUNCount: Int
    let worldProgressPercent: Int
    let visitedContinentsCount: Int
    let totalContinentsCount: Int
    let continentItems: [StatisticsContinentItem]
}

struct StatisticsContinentItem: Equatable {
    let continent: Continent
    let visitedCount: Int
    let totalCount: Int
}
