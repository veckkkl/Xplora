//
//  Note.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

struct NoteLocation: Codable, Equatable {
    var placeName: String
    var city: String
    var country: String
    // ISO 3166-1 alpha-2 code (e.g. "FR"). Optional because legacy notes saved
    // before this field was introduced won't have it, and not every MapKit
    // placemark exposes a country code.
    var countryCode: String?
    var latitude: Double
    var longitude: Double

    var address: String? {
        let parts = [city, country]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    var hasDisplayableValue: Bool {
        !placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        placeName: String,
        city: String,
        country: String,
        countryCode: String? = nil,
        latitude: Double,
        longitude: Double
    ) {
        self.placeName = placeName
        self.city = city
        self.country = country
        self.countryCode = NoteLocation.normalizedCountryCode(countryCode)
        self.latitude = latitude
        self.longitude = longitude
    }

    // Backward-compatible initializer for existing UI integration.
    init(
        placeName: String,
        address: String?,
        countryCode: String? = nil,
        latitude: Double,
        longitude: Double
    ) {
        let trimmedAddress = address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let components = trimmedAddress
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let parsedCity = components.first ?? ""
        let parsedCountry = components.count > 1 ? components.last ?? "" : ""

        self.init(
            placeName: placeName,
            city: parsedCity,
            country: parsedCountry,
            countryCode: countryCode,
            latitude: latitude,
            longitude: longitude
        )
    }

    private static func normalizedCountryCode(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct NotePhoto: Identifiable, Codable, Equatable {
    let id: String
    var localPath: String
    var createdAt: Date
    var orderIndex: Int
    var photoLibraryAssetId: String?
}

struct Note: Identifiable, Equatable {
    let id: String
    var title: String?
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var tripStartDate: Date?
    var tripEndDate: Date?
    var isBookmarked: Bool
    var location: NoteLocation?
    var photos: [NotePhoto]

    // Temporary UI-compatibility fields that are not part of persistence core.
    var headerTitle: String?

    var coordinate: LocationCoordinate? {
        guard let location else { return nil }
        return LocationCoordinate(latitude: location.latitude, longitude: location.longitude)
    }

    var photoURLs: [URL] {
        get {
            // Resolve persisted paths through NotePhotoFileStorage so notes
            // keep working across app relaunches when the container path
            // changes (we store relative paths, legacy absolute paths are
            // resolved as-is).
            photos
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { NotePhotoFileStorage.absoluteURL(for: $0.localPath) }
        }
        set {
            photos = newValue.enumerated().map { index, url in
                NotePhoto(
                    id: UUID().uuidString,
                    localPath: NotePhotoFileStorage.relativePath(for: url),
                    createdAt: Date(),
                    orderIndex: index,
                    photoLibraryAssetId: nil
                )
            }
        }
    }

    var city: String? {
        get {
            guard let location else { return nil }
            let trimmed = location.city.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        set {
            guard var location else { return }
            location.city = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.location = location
        }
    }

    var country: String? {
        get {
            guard let location else { return nil }
            let trimmed = location.country.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        set {
            guard var location else { return }
            location.country = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.location = location
        }
    }
}
