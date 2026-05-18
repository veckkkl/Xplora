//
//  CatalogPlacePolicyTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct CatalogPlacePolicyTests {

    // MARK: - Status mapping

    @Test func franceIsUN() throws {
        let fr = try #require(CatalogPlacePolicy.place(forCode: "FR"))
        #expect(fr.status == .un)
    }

    @Test func palestineIsUN() throws {
        let ps = try #require(CatalogPlacePolicy.place(forCode: "PS"))
        #expect(ps.status == .un)
    }

    @Test func holySeeIsUN() throws {
        let va = try #require(CatalogPlacePolicy.place(forCode: "VA"))
        #expect(va.status == .un)
    }

    @Test func taiwanIsDisputed() throws {
        let tw = try #require(CatalogPlacePolicy.place(forCode: "TW"))
        #expect(tw.status == .disputed)
    }

    @Test func kosovoIsDisputed() throws {
        let xk = try #require(CatalogPlacePolicy.place(forCode: "XK"))
        #expect(xk.status == .disputed)
    }

    @Test func greenlandIsTerritory() throws {
        let gl = try #require(CatalogPlacePolicy.place(forCode: "GL"))
        #expect(gl.status == .territory)
    }

    @Test func faroeIslandsAreTerritory() throws {
        let fo = try #require(CatalogPlacePolicy.place(forCode: "FO"))
        #expect(fo.status == .territory)
    }

    @Test func caymanIslandsAreTerritory() throws {
        let ky = try #require(CatalogPlacePolicy.place(forCode: "KY"))
        #expect(ky.status == .territory)
    }

    @Test func hongKongIsTerritory() throws {
        let hk = try #require(CatalogPlacePolicy.place(forCode: "HK"))
        #expect(hk.status == .territory)
    }

    // MARK: - 195 UN progress

    @Test func unProgressContainsExactly195Codes() {
        #expect(CatalogPlacePolicy.unProgressCodes.count == 195)
    }

    @Test func territoriesAndDisputedDoNotContributeToProgress() {
        let unCodes = CatalogPlacePolicy.unProgressCodes
        // Territories
        #expect(!unCodes.contains("GL"))
        #expect(!unCodes.contains("HK"))
        #expect(!unCodes.contains("PR"))
        #expect(!unCodes.contains("AQ"))
        // Disputed
        #expect(!unCodes.contains("TW"))
        #expect(!unCodes.contains("XK"))
    }

    @Test func unProgressIncludesSpecialUNObservers() {
        #expect(CatalogPlacePolicy.unProgressCodes.contains("VA"))
        #expect(CatalogPlacePolicy.unProgressCodes.contains("PS"))
    }

    // MARK: - Filtering unsupported API entries

    @Test func filterRejectsUnsupportedCodes() {
        let fromAPI = ["FR", "DE", "ZZ", "QQ", "TW"]
        let result = CatalogPlacePolicy.filter(codes: fromAPI)
        let resultCodes = Set(result.map(\.code))

        #expect(resultCodes.contains("FR"))
        #expect(resultCodes.contains("DE"))
        #expect(resultCodes.contains("TW"))
        #expect(!resultCodes.contains("ZZ"))
        #expect(!resultCodes.contains("QQ"))
    }

    @Test func filterPreservesPolicyStatusNotInputOrder() {
        let result = CatalogPlacePolicy.filter(codes: ["TW", "FR"])
        let tw = try? #require(result.first { $0.code == "TW" })
        let fr = try? #require(result.first { $0.code == "FR" })
        #expect(tw?.status == .disputed)
        #expect(fr?.status == .un)
    }

    @Test func filterIsCaseInsensitiveOnInput() {
        let result = CatalogPlacePolicy.filter(codes: ["fr", "gB"])
        let codes = Set(result.map(\.code))
        #expect(codes.contains("FR"))
        #expect(codes.contains("GB"))
    }
}
