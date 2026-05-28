//
//  TravelStatusResolverTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct TravelStatusResolverTests {
    private let sut = TravelStatusResolver()

    @Test func zeroEverything_isAdventureTraveler() {
        let status = sut.resolve(countriesCount: 0, tripsCount: 0, worldProgressPercent: 0)
        #expect(status == .adventureTraveler)
    }

    @Test func fewUniqueWithRepeatedTrips_isFamiliarWanderer() {
        let status = sut.resolve(countriesCount: 2, tripsCount: 6, worldProgressPercent: 1)
        #expect(status == .familiarWanderer)
    }

    @Test func fiveUniqueCountries_isPlaceCollector() {
        let status = sut.resolve(countriesCount: 5, tripsCount: 5, worldProgressPercent: 2)
        #expect(status == .placeCollector)
    }

    @Test func placeCollectorTakesPriorityOverFamiliarWanderer() {
        let status = sut.resolve(countriesCount: 6, tripsCount: 12, worldProgressPercent: 3)
        #expect(status == .placeCollector)
    }

    @Test func highWorldProgress_isWorldExplorer() {
        let status = sut.resolve(countriesCount: 3, tripsCount: 4, worldProgressPercent: 10)
        #expect(status == .worldExplorer)
    }

    @Test func manyCountries_isWorldExplorer() {
        let status = sut.resolve(countriesCount: 15, tripsCount: 15, worldProgressPercent: 4)
        #expect(status == .worldExplorer)
    }
}
