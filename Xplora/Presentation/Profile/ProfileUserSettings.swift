//
//  ProfileUserSettings.swift
//  Xplora
//

import Foundation
import os
import UIKit

enum ProfileUserSettings {
    private enum Keys {
        static let name = "profile.user.name"
        static let isStatusVisible = "profile.user.is_status_visible"
        static let avatarFileName = "profile.user.avatar_file_name"
    }

    static let maxNameLength = 40

    static var currentName: String {
        let stored = UserDefaults.standard.string(forKey: Keys.name) ?? ""
        return stored.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var currentAvatarFileName: String? {
        UserDefaults.standard.string(forKey: Keys.avatarFileName)
    }

    static var isStatusVisible: Bool {
        if UserDefaults.standard.object(forKey: Keys.isStatusVisible) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Keys.isStatusVisible)
    }

    static func saveName(_ name: String) {
        UserDefaults.standard.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.name)
    }

    static func saveStatusVisibility(_ isVisible: Bool) {
        UserDefaults.standard.set(isVisible, forKey: Keys.isStatusVisible)
    }

    @discardableResult
    static func saveAvatarImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }

        let newFileName = "avatar-\(UUID().uuidString).jpg"
        let newFileURL = avatarDirectoryURL.appendingPathComponent(newFileName)

        do {
            try FileManager.default.createDirectory(at: avatarDirectoryURL, withIntermediateDirectories: true)
            try data.write(to: newFileURL, options: .atomic)

            if let oldFileName = currentAvatarFileName, oldFileName != newFileName {
                let oldFileURL = avatarDirectoryURL.appendingPathComponent(oldFileName)
                try? FileManager.default.removeItem(at: oldFileURL)
            }

            UserDefaults.standard.set(newFileName, forKey: Keys.avatarFileName)
            return newFileName
        } catch {
            let nsError = error as NSError
            Logger.storage.error(
                "Avatar save failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            return nil
        }
    }

    /// Removes the stored name, status visibility, avatar reference and the
    /// avatar directory. Throws when the avatar files can't be removed; the
    /// UserDefaults keys are cleared either way.
    static func removeAll(
        defaults: UserDefaults = .standard,
        avatarDirectoryURL: URL = avatarDirectoryURL
    ) throws {
        defaults.removeObject(forKey: Keys.name)
        defaults.removeObject(forKey: Keys.isStatusVisible)
        defaults.removeObject(forKey: Keys.avatarFileName)
        do {
            try FileManager.default.removeItem(at: avatarDirectoryURL)
        } catch CocoaError.fileNoSuchFile {
            return
        }
    }

    static func loadCurrentAvatarImage() -> UIImage? {
        loadAvatarImage(fileName: currentAvatarFileName)
    }

    static func loadAvatarImage(fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        let fileURL = avatarDirectoryURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    /// Up to two initials from the first letters of the name's words, or `nil`
    /// when the name has no letters (the avatar then shows a neutral person icon).
    static func initials(from name: String) -> String? {
        let letters = name
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .compactMap { word in word.first(where: \.isLetter) }
            .prefix(2)
            .map { String($0).uppercased() }

        return letters.isEmpty ? nil : letters.joined()
    }

    static var avatarDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return baseURL.appendingPathComponent("ProfileAvatar", isDirectory: true)
    }
}
