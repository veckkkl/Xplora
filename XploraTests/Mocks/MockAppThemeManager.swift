//
//  MockAppThemeManager.swift
//  XploraTests
//

@testable import Xplora

final class MockAppThemeManager: AppThemeManaging {
    var currentTheme: AppTheme
    private(set) var appliedThemes: [AppTheme] = []

    init(currentTheme: AppTheme = .system) {
        self.currentTheme = currentTheme
    }

    func apply(_ theme: AppTheme) {
        appliedThemes.append(theme)
        currentTheme = theme
    }
}
