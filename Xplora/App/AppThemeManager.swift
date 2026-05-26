//
//  AppThemeManager.swift
//  Xplora
//

import UIKit

enum AppThemeManager {
    private static let userDefaultsKey = "profile.dark_theme_enabled"

    static var isDarkThemeEnabled: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    static func apply(isDark: Bool) {
        UserDefaults.standard.set(isDark, forKey: userDefaultsKey)
        let style: UIUserInterfaceStyle = isDark ? .dark : .light
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
