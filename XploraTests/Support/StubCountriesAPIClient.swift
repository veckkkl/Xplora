//
//  StubCountriesAPIClient.swift
//  XploraTests
//

import Foundation
@testable import Xplora

enum TestError: Error { case boom }

/// In-memory stub for `CountriesAPIClient`. Each per-method response is
/// keyed by country name and overrideable. Call counts let tests assert
/// caching behaviour at the repo boundary.
final class StubCountriesAPIClient: CountriesAPIClient, @unchecked Sendable {
    private let cities: [String: [String]]
    private let capital: [String: String?]
    private let countryCodes: [String]
    private let citiesError: Error?
    private let capitalError: Error?
    private let countryCodesError: Error?

    private let lock = NSLock()
    private(set) var citiesCallCount = 0
    private(set) var capitalCallCount = 0
    private(set) var countryCodesCallCount = 0

    init(
        cities: [String: [String]] = [:],
        capital: [String: String?] = [:],
        countryCodes: [String] = [],
        citiesError: Error? = nil,
        capitalError: Error? = nil,
        countryCodesError: Error? = nil
    ) {
        self.cities = cities
        self.capital = capital
        self.countryCodes = countryCodes
        self.citiesError = citiesError
        self.capitalError = capitalError
        self.countryCodesError = countryCodesError
    }

    func fetchCountryCodes() async throws -> [String] {
        lock.lock(); countryCodesCallCount += 1; lock.unlock()
        if let error = countryCodesError { throw error }
        return countryCodes
    }

    func fetchCities(countryName: String) async throws -> [String] {
        lock.lock(); citiesCallCount += 1; lock.unlock()
        if let error = citiesError { throw error }
        return cities[countryName] ?? []
    }

    func fetchCapital(countryName: String) async throws -> String? {
        lock.lock(); capitalCallCount += 1; lock.unlock()
        if let error = capitalError { throw error }
        return capital[countryName] ?? nil
    }
}
