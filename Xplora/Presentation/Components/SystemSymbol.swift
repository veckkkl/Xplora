//
//  SystemSymbol.swift
//  Xplora
//

import Foundation

/// Type-safe constants for the SF Symbol names used across the UI.
///
/// Mirrors the spirit of the SwiftGen-generated `L10n`: avoids scattering
/// raw symbol identifiers through call sites and surfaces typos at compile
/// time. SF Symbols are provided by the system, so the values are stored as
/// raw strings rather than asset entries.
enum SystemSymbol {
    static let bookmark = "bookmark"
    static let bookmarkFill = "bookmark.fill"
    static let checkmark = "checkmark"
    static let chevronBackward = "chevron.backward"
    static let chevronDown = "chevron.down"
    static let chevronUp = "chevron.up"
    static let magnifyingGlass = "magnifyingglass"
    static let menuDecrease = "line.3.horizontal.decrease"
    static let trash = "trash"
}
