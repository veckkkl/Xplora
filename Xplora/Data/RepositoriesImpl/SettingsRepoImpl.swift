//
//  SettingsRepoImpl.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

final class SettingsRepoImpl: SettingsRepo {
    private let storage: LocalStorageProtocol

    init(storage: LocalStorageProtocol) {
        self.storage = storage
    }

    func loadSettings() async throws -> UserSettings {
        try storage.loadSettings()
    }

    func saveSettings(_ settings: UserSettings) async throws {
        try storage.saveSettings(settings)
    }
}
