//
//  LocalProfileDataStore.swift
//  Xplora
//

import Foundation

final class LocalProfileDataStore: ProfileDataStore {
    private let defaults: UserDefaults
    private let avatarDirectoryURL: URL

    init(
        defaults: UserDefaults = .standard,
        avatarDirectoryURL: URL = ProfileUserSettings.avatarDirectoryURL
    ) {
        self.defaults = defaults
        self.avatarDirectoryURL = avatarDirectoryURL
    }

    func deleteAll() throws {
        AppThemeManager(defaults: defaults).reset()
        try ProfileUserSettings.removeAll(defaults: defaults, avatarDirectoryURL: avatarDirectoryURL)
    }
}
