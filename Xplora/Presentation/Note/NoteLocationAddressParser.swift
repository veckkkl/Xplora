//
//  NoteLocationAddressParser.swift
//  Xplora
//

import Foundation

/// Splits a free-form `"City, Country"`-style address string into city and
/// country components.
///
/// - Empty or whitespace-only input yields empty strings for both.
/// - A single-part input is treated as the city, with an empty country.
/// - For multi-part input, the last two non-empty components are used as
///   city and country respectively.
enum NoteLocationAddressParser {
    static func parseCityCountry(from address: String?) -> (city: String, country: String) {
        let trimmed = address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return ("", "") }
        let parts = trimmed
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            return (parts[parts.count - 2], parts[parts.count - 1])
        }

        return (parts.first ?? "", "")
    }
}
