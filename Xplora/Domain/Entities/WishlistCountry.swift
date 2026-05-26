// WishlistCountry.swift
// Xplora

import Foundation

struct WishlistCountry: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    let code: String
    let flag: String
    let name: String      // EN name kept for Codable compatibility, not used for display
    var cityKey: String?  // localization key for a suggested city (e.g. "city.FR.normandy")
    var note: String?     // raw city text for manual input or legacy data
    var isCompleted: Bool
    let addedAt: Date

    /// Returns the best available localized city name.
    var displayCityNote: String? {
        if let key = cityKey {
            let resolved = Bundle.main.localizedString(forKey: key, value: nil, table: "Localizable")
            if resolved != key { return resolved }
        }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Stable identity used for duplicate detection.
    var cityIdentity: WishlistCityIdentity {
        if let key = cityKey { return .suggested(key: key) }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return .none }
        let normalized = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return .custom(normalized: normalized)
    }
}

// MARK: - WishlistCityIdentity

enum WishlistCityIdentity: Equatable {
    case suggested(key: String)
    case custom(normalized: String)
    case none
}
