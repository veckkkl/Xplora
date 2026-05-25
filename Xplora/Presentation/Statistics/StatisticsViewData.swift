//
//  StatisticsViewData.swift
//  Xplora
//

import Foundation

struct StatisticsViewData {
    let totalCard: StatisticsTotalCardViewData
    let continentsCard: StatisticsSingleValueCardViewData
    let countriesCard: StatisticsSingleValueCardViewData
    let continentCards: [StatisticsSingleValueCardViewData]
}

struct StatisticsTotalCardViewData {
    let title: String
    let subtitle: String
    let leftValue: String
    let leftCaption: String
    let rightValue: String
    let rightCaption: String
}

struct StatisticsSingleValueCardViewData {
    let title: String
    let subtitle: String
    let value: String
}
