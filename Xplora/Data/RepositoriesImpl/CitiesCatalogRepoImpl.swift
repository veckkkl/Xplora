//
//  CitiesCatalogRepoImpl.swift
//  Xplora
//

import Foundation

/// Cities catalog. Curated cities come from the bundled data source. Capital
/// + full city list come from a remote API on-demand and are cached in
/// memory per place. Everything is gated by `CatalogPlacePolicy`: cities of
/// unsupported places are dropped at the repo boundary so no caller needs to
/// repeat the check.
final class CitiesCatalogRepoImpl: CitiesCatalogRepo {
    private let supportedPlaceCodes: Set<String>
    private let bundledCities: [String: [CatalogCity]]
    private let api: CountriesAPIClient?
    private let countryNameProvider: (String) -> String?

    // In-memory caches. `*Fetched` sets remember "we've already tried", so a
    // miss isn't refetched on every keystroke.
    private let cacheLock = NSLock()
    private var capitalCache: [String: CatalogCity] = [:]
    private var capitalFetched: Set<String> = []
    private var allCitiesCache: [String: [CatalogCity]] = [:]
    private var allCitiesFetched: Set<String> = []

    init(
        supportedPlaceCodes: Set<String> = CatalogPlacePolicy.supportedCodes,
        bundledCities: [String: [CatalogCity]] = BundledCitiesDataSource.citiesByPlaceCode,
        api: CountriesAPIClient? = nil,
        countryNameProvider: @escaping (String) -> String? = { code in
            Locale(identifier: "en_US").localizedString(forRegionCode: code)
        }
    ) {
        self.supportedPlaceCodes = supportedPlaceCodes
        self.bundledCities = bundledCities
        self.api = api
        self.countryNameProvider = countryNameProvider
    }

    // MARK: - Curated (bundled)

    func curatedCities(forPlaceCode code: String) async throws -> [CatalogCity] {
        let upper = code.uppercased()
        guard supportedPlaceCodes.contains(upper) else { return [] }
        guard let cities = bundledCities[upper] else { return [] }
        // Defensive: if a city slipped through with a mismatching placeCode,
        // skip it rather than violating the supported-place invariant.
        return cities.filter { $0.placeCode == upper }
    }

    // MARK: - Capital (API + cache)

    func capital(forPlaceCode code: String) async throws -> CatalogCity? {
        let upper = code.uppercased()
        guard supportedPlaceCodes.contains(upper) else { return nil }

        if let entry = readCachedCapital(upper) { return entry }

        guard let api, let countryName = countryNameProvider(upper) else {
            markCapitalFetched(absent: upper)
            return nil
        }

        do {
            let name = try await api.fetchCapital(countryName: countryName)
            let city = name.map { value in
                CatalogCity(
                    id: "\(upper)-capital",
                    fallbackName: value,
                    placeCode: upper
                )
            }
            writeCachedCapital(city, for: upper)
            return city
        } catch {
            markCapitalFetched(absent: upper)
            return nil
        }
    }

    // MARK: - All cities (API + cache)

    func allCities(forPlaceCode code: String) async throws -> [CatalogCity] {
        let upper = code.uppercased()
        guard supportedPlaceCodes.contains(upper) else { return [] }

        if let cached = readCachedAllCities(upper) { return cached }

        guard let api, let countryName = countryNameProvider(upper) else {
            writeCachedAllCities([], for: upper)
            return []
        }

        do {
            let names = try await api.fetchCities(countryName: countryName)
            let cities = names.enumerated().map { index, name -> CatalogCity in
                CatalogCity(
                    id: "\(upper)-api-\(slugify(name))-\(index)",
                    fallbackName: name,
                    placeCode: upper
                )
            }
            writeCachedAllCities(cities, for: upper)
            return cities
        } catch {
            writeCachedAllCities([], for: upper)
            return []
        }
    }

    // MARK: - Global search

    func search(query: String) async throws -> [CatalogCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalized = trimmed
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        var seen: Set<String> = []
        var matches: [CatalogCity] = []

        for (code, cities) in bundledCities {
            guard supportedPlaceCodes.contains(code) else { continue }
            for city in cities {
                guard !seen.contains(city.id) else { continue }
                let displayMatch = city.displayName
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .contains(normalized)
                let fallbackMatch = city.fallbackName
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .contains(normalized)
                if displayMatch || fallbackMatch {
                    matches.append(city)
                    seen.insert(city.id)
                }
            }
        }

        return matches.sorted {
            $0.displayName.localizedCompare($1.displayName) == .orderedAscending
        }
    }

    // MARK: - Cache helpers

    private func readCachedCapital(_ code: String) -> CatalogCity?? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        guard capitalFetched.contains(code) else { return nil }
        return .some(capitalCache[code])
    }

    private func writeCachedCapital(_ value: CatalogCity?, for code: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        capitalFetched.insert(code)
        if let value {
            capitalCache[code] = value
        } else {
            capitalCache.removeValue(forKey: code)
        }
    }

    private func markCapitalFetched(absent code: String) {
        writeCachedCapital(nil, for: code)
    }

    private func readCachedAllCities(_ code: String) -> [CatalogCity]? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        guard allCitiesFetched.contains(code) else { return nil }
        return allCitiesCache[code] ?? []
    }

    private func writeCachedAllCities(_ value: [CatalogCity], for code: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        allCitiesFetched.insert(code)
        allCitiesCache[code] = value
    }

    // MARK: - Slug

    private func slugify(_ name: String) -> String {
        let folded = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
            .lowercased()
        var slug = ""
        var lastWasSeparator = true
        for char in folded {
            if char.isLetter || char.isNumber {
                slug.append(char)
                lastWasSeparator = false
            } else if !lastWasSeparator {
                slug.append("_")
                lastWasSeparator = true
            }
        }
        if slug.last == "_" { slug.removeLast() }
        return slug
    }
}
