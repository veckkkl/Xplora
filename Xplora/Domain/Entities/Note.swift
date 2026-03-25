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

    init(placeName: String, city: String, country: String, latitude: Double, longitude: Double) {
        self.placeName = placeName
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }

    // Backward-compatible initializer for existing UI integration.
    init(placeName: String, address: String?, latitude: Double, longitude: Double) {
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
            latitude: latitude,
            longitude: longitude
        )
    }
}

struct NotePhoto: Identifiable, Codable, Equatable {
    let id: String
    var localPath: String
    var createdAt: Date
    var orderIndex: Int
}

struct Note: Identifiable, Equatable {
    let id: String
    var title: String?
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var isBookmarked: Bool
    var location: NoteLocation
    var photos: [NotePhoto]

    // Temporary UI-compatibility fields that are not part of persistence core.
    var dateRangeText: String?
    var headerTitle: String?

    var coordinate: LocationCoordinate {
        LocationCoordinate(latitude: location.latitude, longitude: location.longitude)
    }

    var photoURLs: [URL] {
        get {
            photos
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { photo in
                    if photo.localPath.hasPrefix("/") {
                        return URL(fileURLWithPath: photo.localPath)
                    }
                    return Note.applicationSupportDirectoryURL()
                        .appendingPathComponent(photo.localPath, isDirectory: false)
                }
        }
        set {
            photos = newValue.enumerated().map { index, url in
                NotePhoto(
                    id: UUID().uuidString,
                    localPath: Note.localPath(from: url),
                    createdAt: Date(),
                    orderIndex: index
                )
            }
        }
    }

    var city: String? {
        get {
            let trimmed = location.city.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        set {
            location.city = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
    }

    var country: String? {
        get {
            let trimmed = location.country.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        set {
            location.country = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
    }

    private static func applicationSupportDirectoryURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    private static func localPath(from url: URL) -> String {
        let absolutePath = url.path
        let prefix = applicationSupportDirectoryURL().path + "/"
        if absolutePath.hasPrefix(prefix) {
            return String(absolutePath.dropFirst(prefix.count))
        }
        return absolutePath
    }
}
