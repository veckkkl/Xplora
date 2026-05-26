// CountryLocalizer.swift
// Xplora

import Foundation

enum CountryLocalizer {
    static func name(for code: String, fallback: String? = nil) -> String {
        if let localized = Locale.current.localizedString(forRegionCode: code) {
            return localized
        }
        return fallback ?? code
    }
}
