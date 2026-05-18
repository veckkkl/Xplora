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
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw CountriesAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CountriesAPIError.http(status: http.statusCode)
        }

        let envelope: CountryPositionsEnvelope
        do {
            envelope = try JSONDecoder().decode(CountryPositionsEnvelope.self, from: data)
        } catch {
            throw CountriesAPIError.decodingFailed
        }

        if envelope.error {
            throw CountriesAPIError.apiReturnedError(message: envelope.msg ?? "Unknown API error")
        }

        return envelope.data.map { $0.iso2.uppercased() }
    }
}

// MARK: - DTO

private struct CountryPositionsEnvelope: Decodable {
    let error: Bool
    let msg: String?
    let data: [CountryPositionDTO]
}

private struct CountryPositionDTO: Decodable {
    let iso2: String
}
