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
        guard let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
              let language = AppLanguage(rawValue: rawValue) else {
            return defaultLanguage
        }
        return language
    }

    static func save(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
    }

    var displayName: String {
        switch self {
        case .ru:
            return L10n.Profile.Language.russianNative
        case .en:
            return L10n.Profile.Language.englishNative
        }
    }

    private static var defaultLanguage: AppLanguage {
        let systemCode = Locale.current.language.languageCode?.identifier ?? "en"
        return systemCode.hasPrefix("ru") ? .ru : .en
    }
}
