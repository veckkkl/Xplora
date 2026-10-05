//
//  AppLanguage.swift
//  Xplora
//

import Foundation

/// Language the app UI is actually rendered in. The choice itself is owned by
/// iOS (Settings → Xplora → Language), so nothing is stored here.
enum AppLanguage: String, CaseIterable {
    case ru
    case en

    static let fallback: AppLanguage = .en

    static var current: AppLanguage {
        resolve(preferredLocalizations: Bundle.main.preferredLocalizations)
    }

    static func resolve(preferredLocalizations: [String]) -> AppLanguage {
        preferredLocalizations.lazy.compactMap(AppLanguage.init(localeCode:)).first ?? fallback
    }

    /// Earlier builds saved an in-app language pick that iOS never honoured.
    static func removeLegacyStoredSelection(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: legacySelectionKey)
    }

    static let legacySelectionKey = "profile.selected_language"

    var displayName: String {
        switch self {
        case .ru:
            return L10n.Profile.Language.nativeRussian
        case .en:
            return L10n.Profile.Language.nativeEnglish
        }
    }

    // Matches "ru", "ru-RU", "en_US", etc. against short rawValue codes.
    private init?(localeCode: String) {
        let prefix = localeCode.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? localeCode
        self.init(rawValue: prefix.lowercased())
    }
}
