//
//  Trip.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

struct Trip: Identifiable, Equatable, Codable {
    let id: UUID
    /// ISO 3166-1 alpha-2 code from the unified Xplora catalog (`CatalogPlace`).
    /// Hong Kong / Taiwan / Antarctica are preserved as their own codes — never
    /// collapsed into a parent country.
    let placeCode: String
    let startDate: Date
    let endDate: Date
    let notesCount: Int
    let visitedPlaces: [VisitedPlace]

    init(
        id: UUID,
        placeCode: String,
        startDate: Date,
        endDate: Date,
        notesCount: Int,
        visitedPlaces: [VisitedPlace]
    ) {
        self.id = id
        self.placeCode = placeCode
        self.startDate = startDate
        self.endDate = endDate
        self.notesCount = notesCount
        self.visitedPlaces = visitedPlaces
    }

    // MARK: - Codable (backward-compatible)
    //
    // Old payloads stored the full `Country` blob under the `country` key:
    //
    //   { "country": { "id": "...", "code": "IT", "name": "Italy", "regions": [] }, ... }
    //
    // New payloads write only the canonical `placeCode`:
    //
    //   { "placeCode": "IT", ... }
    //
    // Decoder accepts both shapes so existing LocalStorage data continues to
    // load. Encoder always writes the new shape, so re-saving migrates rows.

    private enum CodingKeys: String, CodingKey {
        case id
        case placeCode
        case country // legacy
        case startDate
        case endDate
        case notesCount
        case visitedPlaces
    }

    private struct LegacyCountry: Decodable {
        let code: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        if let code = try container.decodeIfPresent(String.self, forKey: .placeCode) {
            self.placeCode = code
        } else {
            let legacy = try container.decode(LegacyCountry.self, forKey: .country)
            self.placeCode = legacy.code
        }
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.notesCount = try container.decode(Int.self, forKey: .notesCount)
        self.visitedPlaces = try container.decode([VisitedPlace].self, forKey: .visitedPlaces)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(placeCode, forKey: .placeCode)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(notesCount, forKey: .notesCount)
        try container.encode(visitedPlaces, forKey: .visitedPlaces)
    }
}

struct VisitedPlace: Identifiable, Equatable, Codable {
    let id: UUID
    let city: City
    let date: Date
}
