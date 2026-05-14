//
//  AuthUser.swift
//  Xplora
//

import Foundation

struct AuthUser: Codable, Equatable {
    let id: String
    let name: String
    let createdAt: Date
    let residenceCountryCode: String?
    let isWorldCitizen: Bool

    init(id: String, name: String, createdAt: Date, residenceCountryCode: String?, isWorldCitizen: Bool) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.residenceCountryCode = residenceCountryCode
        self.isWorldCitizen = isWorldCitizen
    }

    // Graceful migration: old stored data without country fields decodes cleanly.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        residenceCountryCode = try c.decodeIfPresent(String.self, forKey: .residenceCountryCode)
        isWorldCitizen = try c.decodeIfPresent(Bool.self, forKey: .isWorldCitizen) ?? false
    }
}
