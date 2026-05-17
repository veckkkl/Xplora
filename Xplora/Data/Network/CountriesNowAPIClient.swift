//
//  CountriesNowAPIClient.swift
//  Xplora
//

import Foundation

enum CountriesAPIError: Error {
    case invalidResponse
    case http(status: Int)
    case decodingFailed
    case apiReturnedError(message: String)
}

protocol CountriesAPIClient {
    /// Returns the list of ISO 3166-1 alpha-2 country codes available in the catalog.
    func fetchCountryCodes() async throws -> [String]

    /// Returns the full list of city names for a country.
    /// `countryName` must be the English name accepted by the API
    /// (e.g. "France", "United States"). Errors propagate so callers can
    /// decide whether to degrade silently.
    func fetchCities(countryName: String) async throws -> [String]

    /// Returns the capital city name for a country, or `nil` if the API has
    /// no capital data for it. Empty / blank values are normalised to `nil`.
    func fetchCapital(countryName: String) async throws -> String?
}

final class CountriesNowAPIClient: CountriesAPIClient {
    private let session: URLSession
    private let baseURL: URL

    init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://countriesnow.space/api/v0.1")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchCountryCodes() async throws -> [String] {
        let url = baseURL.appendingPathComponent("countries/positions")
        let data = try await get(url: url)

        let envelope = try decode(CountryPositionsEnvelope.self, from: data)
        try ensureNoAPIError(envelope.error, message: envelope.msg)
        return envelope.data.map { $0.iso2.uppercased() }
    }

    func fetchCities(countryName: String) async throws -> [String] {
        let url = baseURL.appendingPathComponent("countries/cities")
        let data = try await post(url: url, body: ["country": countryName])

        let envelope = try decode(CitiesEnvelope.self, from: data)
        try ensureNoAPIError(envelope.error, message: envelope.msg)
        return envelope.data ?? []
    }

    func fetchCapital(countryName: String) async throws -> String? {
        let url = baseURL.appendingPathComponent("countries/capital")
        let data = try await post(url: url, body: ["country": countryName])

        let envelope = try decode(CapitalEnvelope.self, from: data)
        try ensureNoAPIError(envelope.error, message: envelope.msg)
        let trimmed = envelope.data?.capital?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    // MARK: - HTTP helpers

    private func get(url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        try validate(response)
        return data
    }

    private func post(url: URL, body: [String: String]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validate(response)
        return data
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw CountriesAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CountriesAPIError.http(status: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CountriesAPIError.decodingFailed
        }
    }

    private func ensureNoAPIError(_ error: Bool, message: String?) throws {
        if error {
            throw CountriesAPIError.apiReturnedError(message: message ?? "Unknown API error")
        }
    }
}

// MARK: - DTOs

private struct CountryPositionsEnvelope: Decodable {
    let error: Bool
    let msg: String?
    let data: [CountryPositionDTO]
}

private struct CountryPositionDTO: Decodable {
    let iso2: String
}

private struct CitiesEnvelope: Decodable {
    let error: Bool
    let msg: String?
    let data: [String]?
}

private struct CapitalEnvelope: Decodable {
    let error: Bool
    let msg: String?
    let data: CapitalDTO?
}

private struct CapitalDTO: Decodable {
    let capital: String?
}
