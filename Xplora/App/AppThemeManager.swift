//
//  AppThemeManager.swift
//  Xplora
//

import UIKit

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var title: String {
        switch self {
        case .system: return L10n.Profile.Theme.system
        case .light:  return L10n.Profile.Theme.light
        case .dark:   return L10n.Profile.Theme.dark
        }
    }
}

protocol AppThemeManaging {
    var currentTheme: AppTheme { get }
    @MainActor func apply(_ theme: AppTheme)
}

struct AppThemeManager: AppThemeManaging {
    static let storageKey = "app.theme"
    // Before System/Light/Dark the app stored a single "dark theme" switch.
    static let legacyDarkThemeKey = "profile.dark_theme_enabled"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentTheme: AppTheme {
        if let rawValue = defaults.string(forKey: Self.storageKey),
           let theme = AppTheme(rawValue: rawValue) {
            return theme
        }
        if defaults.object(forKey: Self.legacyDarkThemeKey) != nil {
            return defaults.bool(forKey: Self.legacyDarkThemeKey) ? .dark : .light
        }
        return .system
    }

    /// Moves an explicit Light/Dark choice from the legacy switch to the new key.
    func migrateLegacyValueIfNeeded() {
        guard defaults.string(forKey: Self.storageKey) == nil,
              defaults.object(forKey: Self.legacyDarkThemeKey) != nil else { return }
        defaults.set(currentTheme.rawValue, forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.legacyDarkThemeKey)
    }

    /// Forgets the stored choice so the app follows the system appearance.
    func reset() {
        defaults.removeObject(forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.legacyDarkThemeKey)
    }

    @MainActor
    func apply(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.legacyDarkThemeKey)
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows {
                window.overrideUserInterfaceStyle = theme.userInterfaceStyle
            }
        }
    }
}
