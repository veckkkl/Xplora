//
//  AppThemeManagerTests.swift
//  XploraTests
//

import Testing
import Foundation
import UIKit
@testable import Xplora

@MainActor
struct AppThemeManagerTests {

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppThemeManagerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Mapping

    @Test func userInterfaceStyle_mapsEachTheme() {
        #expect(AppTheme.system.userInterfaceStyle == .unspecified)
        #expect(AppTheme.light.userInterfaceStyle == .light)
        #expect(AppTheme.dark.userInterfaceStyle == .dark)
    }

    @Test func allCases_areSystemLightDarkInOrder() {
        #expect(AppTheme.allCases == [.system, .light, .dark])
    }

    @Test func title_isNonEmptyForEveryTheme() {
        for theme in AppTheme.allCases {
            #expect(!theme.title.isEmpty)
        }
    }

    // MARK: - Defaults and persistence

    @Test func currentTheme_newUser_isSystem() {
        let sut = AppThemeManager(defaults: makeDefaults())
        #expect(sut.currentTheme == .system)
    }

    @Test func apply_persistsThemeAcrossInstances() {
        let defaults = makeDefaults()
        AppThemeManager(defaults: defaults).apply(.light)
        #expect(AppThemeManager(defaults: defaults).currentTheme == .light)

        AppThemeManager(defaults: defaults).apply(.system)
        #expect(AppThemeManager(defaults: defaults).currentTheme == .system)
    }

    @Test func currentTheme_unknownStoredValue_fallsBackToSystem() {
        let defaults = makeDefaults()
        defaults.set("sepia", forKey: AppThemeManager.storageKey)
        #expect(AppThemeManager(defaults: defaults).currentTheme == .system)
    }

    // MARK: - Legacy migration

    @Test func legacyDarkEnabled_migratesToDark() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppThemeManager.legacyDarkThemeKey)
        let sut = AppThemeManager(defaults: defaults)

        #expect(sut.currentTheme == .dark)
        sut.migrateLegacyValueIfNeeded()

        #expect(defaults.string(forKey: AppThemeManager.storageKey) == AppTheme.dark.rawValue)
        #expect(defaults.object(forKey: AppThemeManager.legacyDarkThemeKey) == nil)
        #expect(sut.currentTheme == .dark)
    }

    @Test func legacyDarkDisabled_migratesToLight() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppThemeManager.legacyDarkThemeKey)
        let sut = AppThemeManager(defaults: defaults)

        sut.migrateLegacyValueIfNeeded()

        #expect(defaults.string(forKey: AppThemeManager.storageKey) == AppTheme.light.rawValue)
        #expect(sut.currentTheme == .light)
    }

    @Test func migration_withoutLegacyValue_keepsSystemAndWritesNothing() {
        let defaults = makeDefaults()
        let sut = AppThemeManager(defaults: defaults)

        sut.migrateLegacyValueIfNeeded()

        #expect(defaults.string(forKey: AppThemeManager.storageKey) == nil)
        #expect(sut.currentTheme == .system)
    }

    @Test func migration_doesNotOverrideNewValue() {
        let defaults = makeDefaults()
        defaults.set(AppTheme.system.rawValue, forKey: AppThemeManager.storageKey)
        defaults.set(true, forKey: AppThemeManager.legacyDarkThemeKey)
        let sut = AppThemeManager(defaults: defaults)

        sut.migrateLegacyValueIfNeeded()

        #expect(sut.currentTheme == .system)
    }
}
