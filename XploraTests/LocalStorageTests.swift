//
//  LocalStorageTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

@Suite(.serialized)
final class LocalStorageTests {
    private let suiteName = "LocalStorageTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let sut: LocalStorage

    private static let tripsKey = "trips"

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        sut = LocalStorage(userDefaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeTrip(placeCode: String = "FR") -> Trip {
        Trip(
            id: UUID(),
            placeCode: placeCode,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            notesCount: 0,
            visitedPlaces: []
        )
    }

    private struct FailingEncodable: Codable {
        struct Failure: Error {}
        func encode(to encoder: Encoder) throws { throw Failure() }
    }

    // MARK: - Missing data

    @Test func load_whenKeyMissing_returnsNil() throws {
        #expect(try sut.load([Trip].self, forKey: Self.tripsKey) == nil)
    }

    @Test func loadTrips_whenKeyMissing_returnsEmpty() throws {
        #expect(try sut.loadTrips().isEmpty)
    }

    @Test func loadSettings_whenKeyMissing_returnsDefault() throws {
        let settings = try sut.loadSettings()
        #expect(settings.preferredUnits == UserSettings.default.preferredUnits)
        #expect(settings.showFog == UserSettings.default.showFog)
    }

    // MARK: - Round trip

    @Test func saveTrips_thenLoad_returnsSameTrips() throws {
        let trips = [makeTrip(placeCode: "FR"), makeTrip(placeCode: "IT")]
        try sut.saveTrips(trips)
        #expect(try sut.loadTrips() == trips)
    }

    @Test func saveTrips_overwritesPreviousValue() throws {
        try sut.saveTrips([makeTrip(placeCode: "FR")])
        let updated = [makeTrip(placeCode: "DE")]
        try sut.saveTrips(updated)
        #expect(try sut.loadTrips() == updated)
    }

    @Test func saveCachedCatalogCodes_nil_removesValue() throws {
        try sut.saveCachedCatalogCodes(["FR"])
        try sut.saveCachedCatalogCodes(nil)
        #expect(try sut.loadCachedCatalogCodes() == nil)
    }

    // MARK: - Corrupted data

    @Test func loadTrips_whenJSONInvalid_throwsDecodingFailed() {
        defaults.set(Data("not json".utf8), forKey: Self.tripsKey)
        #expect {
            try sut.loadTrips()
        } throws: { error in
            guard case LocalStorageError.decodingFailed(let key, _) = error else { return false }
            return key == Self.tripsKey
        }
    }

    @Test func loadTrips_whenJSONIncompatibleWithModel_throws() {
        defaults.set(Data(#"[{"id":"x"}]"#.utf8), forKey: Self.tripsKey)
        #expect(throws: LocalStorageError.self) { try sut.loadTrips() }
    }

    @Test func load_whenStoredValueIsNotData_throws() {
        defaults.set("plain string", forKey: Self.tripsKey)
        #expect(throws: LocalStorageError.self) { try sut.loadTrips() }
    }

    @Test func loadTrips_whenDecodingFails_leavesStoredDataUntouched() {
        let corrupted = Data("not json".utf8)
        defaults.set(corrupted, forKey: Self.tripsKey)
        _ = try? sut.loadTrips()
        #expect(defaults.data(forKey: Self.tripsKey) == corrupted)
    }

    // MARK: - Write errors

    @Test func save_whenEncodingFails_throwsAndKeepsPreviousValue() throws {
        let trips = [makeTrip()]
        try sut.saveTrips(trips)
        let before = defaults.data(forKey: Self.tripsKey)

        #expect {
            try sut.save(FailingEncodable(), forKey: Self.tripsKey)
        } throws: { error in
            guard case LocalStorageError.encodingFailed(let key, _) = error else { return false }
            return key == Self.tripsKey
        }
        #expect(defaults.data(forKey: Self.tripsKey) == before)
        #expect(try sut.loadTrips() == trips)
    }
}
