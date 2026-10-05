//
//  AppLanguageTests.swift
//  XploraTests
//

import Testing
import Foundation
@testable import Xplora

struct AppLanguageTests {

    @Test func resolve_russianLocalization_isRussian() {
        #expect(AppLanguage.resolve(preferredLocalizations: ["ru"]) == .ru)
    }

    @Test func resolve_englishLocalization_isEnglish() {
        #expect(AppLanguage.resolve(preferredLocalizations: ["en"]) == .en)
    }

    @Test func resolve_regionalCodes_matchBaseLanguage() {
        #expect(AppLanguage.resolve(preferredLocalizations: ["ru-RU"]) == .ru)
        #expect(AppLanguage.resolve(preferredLocalizations: ["en_GB"]) == .en)
    }

    @Test func resolve_skipsUnsupportedLanguages() {
        #expect(AppLanguage.resolve(preferredLocalizations: ["de", "ru"]) == .ru)
    }

    @Test func resolve_noSupportedLanguage_fallsBackToEnglish() {
        #expect(AppLanguage.resolve(preferredLocalizations: ["de", "fr"]) == .en)
        #expect(AppLanguage.resolve(preferredLocalizations: []) == .en)
        #expect(AppLanguage.fallback == .en)
    }

    @Test func current_matchesBundleResolvedLocalization() {
        #expect(AppLanguage.current == AppLanguage.resolve(preferredLocalizations: Bundle.main.preferredLocalizations))
    }

    @Test func removeLegacyStoredSelection_clearsStaleValue() {
        let suiteName = "AppLanguageTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("ru", forKey: AppLanguage.legacySelectionKey)

        AppLanguage.removeLegacyStoredSelection(from: defaults)

        #expect(defaults.object(forKey: AppLanguage.legacySelectionKey) == nil)
    }
}
