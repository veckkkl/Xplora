// WishlistAddResult.swift
// Xplora

import Foundation

enum WishlistAddResult {
    case added
    case exactDuplicate
    case needsConfirmation(WishlistAddConfirmation)
}

enum WishlistAddConfirmation {
    /// A country-only entry already exists; user is adding a city-specific one.
    case countryAlreadyExistsWithoutCity
    /// City-specific entries already exist; user is adding the country without a city.
    case countryAlreadyHasCities
}
