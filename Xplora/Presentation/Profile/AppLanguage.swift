//
//  AppLanguage.swift
//  Xplora
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case ru
    case en

    private static let userDefaultsKey = "profile.selected_language"

    static var current: AppLanguage {
        if let bundleCode = Bundle.main.preferredLocalizations.first,
           let language = AppLanguage(localeCode: bundleCode) {
            return language
        }
        if let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: rawValue) {
            return language
        }
        return defaultLanguage
    }

    static func save(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
    }

    var displayName: String {
        switch self {
        case .ru:
            return L10n.Profile.Language.nativeRussian
        case .en:
            return L10n.Profile.Language.nativeEnglish
        }
    }

    // Matches "ru", "ru-RU", "en", "en-US", etc. against short rawValue codes.
    private init?(localeCode: String) {
        let prefix = localeCode.split(separator: "-", maxSplits: 1).first.map(String.init) ?? localeCode
        self.init(rawValue: prefix)
    }

    private static var defaultLanguage: AppLanguage {
        let systemCode = Locale.current.language.languageCode?.identifier ?? "en"
        return systemCode.hasPrefix("ru") ? .ru : .en
    }
}
