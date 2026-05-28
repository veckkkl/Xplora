//
//  TravelStatusResolver.swift
//  Xplora
//

import Foundation

struct TravelStatusResolver {
    func resolve(
        countriesCount: Int,
        tripsCount: Int,
        worldProgressPercent: Double
    ) -> TravelStatus {
        if worldProgressPercent >= 8 || countriesCount >= 15 {
            return .worldExplorer
        }

        if countriesCount >= 5 {
            return .placeCollector
        }

        let repeatedTripsCount = max(tripsCount - countriesCount, 0)
        let repeatRatio: Double = tripsCount == 0
            ? 0
            : Double(repeatedTripsCount) / Double(tripsCount)

        if tripsCount >= 5 && repeatRatio >= 0.5 {
            return .familiarWanderer
        }

        return .adventureTraveler
    }
}
